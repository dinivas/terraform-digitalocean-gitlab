data "digitalocean_vpc" "gitlab_server_network" {
  count = var.enable_gitlab_server

  name = var.gitlab_server_network
}

data "digitalocean_ssh_key" "gitlab_server" {
  count = var.enable_gitlab_server

  name = "${var.project_name}-project-keypair"
}


data "http" "generic_user_data_template" {
  url = var.generic_user_data_file_url
}

data "template_file" "master_user_data" {
  count = var.gitlab_server_instance_count * var.enable_gitlab_server

  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "digitalocean"
    project_name              = var.project_name
    consul_agent_mode         = "client"
    consul_cluster_domain     = "${var.project_consul_domain}"
    consul_cluster_datacenter = "${var.project_consul_datacenter}"
    consul_cluster_name       = "${var.project_name}-consul"
    do_region                 = var.gitlab_server_availability_zone
    do_api_token              = var.do_api_token
    enable_logging_graylog    = var.gitlab_server_enable_logging_graylog

    pre_configure_script     = ""
    custom_write_files_block = "${data.template_file.master_custom_user_data.0.rendered}"
    post_configure_script    = ""
  }
}

data "template_file" "master_custom_user_data" {
  count = var.gitlab_server_instance_count * var.enable_gitlab_server

  template = file("${path.module}/templates/jenkins-master-user-data.tpl")

  vars = {
    project_name                               = "${var.project_name}"
    gitlab_server_name                        = "${var.gitlab_server_name}"
    gitlab_server_username                    = "${var.gitlab_server_username}"
    gitlab_server_password                    = "${var.gitlab_server_password}"
    gitlab_server_use_keycloak                = "${var.gitlab_server_use_keycloak}"
    gitlab_server_keycloak_host               = "${var.gitlab_server_keycloak_host}"
    gitlab_server_keycloak_client_id          = "${var.gitlab_server_keycloak_client_id}"
    gitlab_server_register_exporter_to_consul = "${var.gitlab_server_register_exporter_to_consul}"
  }
}

resource "digitalocean_droplet" "gitlab_server_instance" {
  count = var.gitlab_server_instance_count * var.enable_gitlab_server

  name               = format("%s-%s", var.gitlab_server_name, count.index)
  image              = var.gitlab_server_image_name
  size               = var.gitlab_server_compute_flavor_name
  ssh_keys           = [data.digitalocean_ssh_key.gitlab_server.0.id]
  region             = var.gitlab_server_availability_zone
  vpc_uuid           = data.digitalocean_vpc.gitlab_server_network.0.id
  user_data          = data.template_file.master_user_data.0.rendered
  tags               = concat([var.project_name], split(",", format("consul_cluster_name_%s-%s,project_%s", var.project_name, "consul", var.project_name)))
  private_networking = true
}

resource "null_resource" "gitlab_server_instance_consul_client_leave" {
  count = var.gitlab_server_instance_count * var.enable_gitlab_server

  triggers = {
    private_ip                               = digitalocean_droplet.gitlab_server_instance[count.index].ipv4_address_private
    host_private_key                         = var.host_private_key
    bastion_host                             = lookup(var.ssh_via_bastion_config, "bastion_host")
    bastion_port                             = lookup(var.ssh_via_bastion_config, "bastion_port")
    bastion_ssh_user                         = lookup(var.ssh_via_bastion_config, "bastion_ssh_user")
    bastion_private_key                      = var.bastion_private_key
    execute_on_destroy_gitlab_server_script = join(",", var.execute_on_destroy_gitlab_server_script)
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
    inline     = split(",", self.triggers.execute_on_destroy_gitlab_server_script)
    on_failure = continue
  }

}
