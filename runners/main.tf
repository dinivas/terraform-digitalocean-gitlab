data "digitalocean_vpc" "gitlab_runner_network" {
  count = var.gitlab_runner_group_instance_count

  name = var.gitlab_runner_network
}
data "http" "generic_user_data_template" {
  url = var.generic_user_data_file_url
}

data "digitalocean_ssh_key" "gitlab_runner" {
  count = var.gitlab_runner_group_instance_count

  name = "${var.project_name}-project-keypair"
}

// ############# Slaves #####################

data "template_file" "gitlab_runner_user_data" {
  count = var.gitlab_runner_group_instance_count

  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "digitalocean"
    consul_agent_mode         = "client"
    consul_cluster_domain     = var.project_consul_domain
    consul_cluster_datacenter = var.project_consul_datacenter
    consul_cluster_name       = "${var.project_name}-consul"
    do_region                 = var.gitlab_runner_availability_zone
    do_api_token              = var.do_api_token
    enable_logging_graylog    = var.gitlab_runner_group_enable_logging_graylog

    pre_configure_script     = <<-EOT
      curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
      chmod +x /usr/local/bin/gitlab-runner
      useradd --comment 'Dinivas GitLab Runner' --create-home gitlab-runner --shell /bin/bash
      gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
      gitlab-runner start
    EOT
    custom_write_files_block = "${lookup(data.template_file.gitlab_runner_custom_user_data[count.index], "rendered")}"
    post_configure_script    = <<-EOT
      sh -c /etc/register-gitlab-runner.sh
    EOT
  }
}

data "template_file" "gitlab_runner_custom_user_data" {
  count = var.gitlab_runner_group_instance_count

  template = file("${path.module}/templates/gitlab-runner-user-data.tpl")

  vars = {
    gitlab_runner_group_gitlab_url   = var.gitlab_runner_group_gitlab_url
    gitlab_runner_group_gitlab_token = var.gitlab_runner_group_gitlab_token
    gitlab_runner_group_executor     = var.gitlab_runner_group_executor
    gitlab_runner_group_name         = format("%s-%s", var.gitlab_runner_group_name, count.index)
    gitlab_runner_description        = format("Dinivas managed Runner: %s-%s", var.gitlab_runner_group_name, count.index)
    gitlab_runner_group_executor     = var.gitlab_runner_group_executor
    gitlab_runner_group_tags         = join(" ", split(",", var.gitlab_runner_group_tags))
    gitlab_runner_group_docker_image = var.gitlab_runner_group_docker_image
  }

}

resource "digitalocean_droplet" "gitlab_runner" {
  count = var.gitlab_runner_group_instance_count

  name      = format("%s-%s", var.gitlab_runner_group_name, count.index)
  image     = var.gitlab_runner_group_cloud_image
  size      = var.gitlab_runner_group_cloud_flavor
  ssh_keys  = [data.digitalocean_ssh_key.gitlab_runner.0.id]
  region    = var.gitlab_runner_availability_zone
  vpc_uuid  = data.digitalocean_vpc.gitlab_runner_network.0.id
  user_data = lookup(data.template_file.gitlab_runner_user_data[count.index], "rendered")
  tags      = concat([var.project_name], split(",", format("consul_cluster_name_%s-%s,project_%s", var.project_name, "consul", var.project_name)))

}

resource "null_resource" "gitlab_runner_instance_consul_client_leave" {
  count = var.gitlab_runner_group_instance_count

  triggers = {
    private_ip                              = digitalocean_droplet.gitlab_runner[count.index].ipv4_address_private
    host_private_key                        = var.host_private_key
    bastion_host                            = lookup(var.ssh_via_bastion_config, "bastion_host")
    bastion_port                            = lookup(var.ssh_via_bastion_config, "bastion_port")
    bastion_ssh_user                        = lookup(var.ssh_via_bastion_config, "bastion_ssh_user")
    bastion_private_key                     = var.bastion_private_key
    execute_on_destroy_gitlab_runner_script = join(",", var.execute_on_destroy_gitlab_runner_script)
  }

  connection {
    type        = "ssh"
    user        = "root"
    port        = 22
    host        = self.triggers.private_ip
    private_key = self.triggers.host_private_key
    agent       = false

    bastion_host        = self.triggers.bastion_host
    bastion_port        = self.triggers.bastion_port
    bastion_user        = self.triggers.bastion_ssh_user
    bastion_private_key = self.triggers.bastion_private_key
  }

  provisioner "remote-exec" {
    when       = destroy
    inline     = split(",", self.triggers.execute_on_destroy_gitlab_runner_script)
    on_failure = continue
  }

}
