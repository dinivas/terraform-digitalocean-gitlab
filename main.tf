data "digitalocean_vpc" "jenkins_master_network" {
  count = var.enable_jenkins_master

  name = var.jenkins_master_network
}

data "digitalocean_ssh_key" "jenkins_master" {
  count = var.enable_jenkins_master

  name = "${var.project_name}-project-keypair"
}


data "http" "generic_user_data_template" {
  url = var.generic_user_data_file_url
}

data "template_file" "master_user_data" {
  count = var.jenkins_master_instance_count

  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "digitalocean"
    project_name              = var.project_name
    consul_agent_mode         = "client"
    consul_cluster_domain     = "${var.project_consul_domain}"
    consul_cluster_datacenter = "${var.project_consul_datacenter}"
    consul_cluster_name       = "${var.project_name}-consul"
    do_region                 = var.jenkins_master_availability_zone
    do_api_token              = var.do_api_token
    enable_logging_graylog    = var.jenkins_master_enable_logging_graylog

    pre_configure_script     = <<-EOT
      useradd -g jenkins jenkins
    EOT
    custom_write_files_block = "${data.template_file.master_custom_user_data.0.rendered}"
    post_configure_script    = ""
  }
}

data "template_file" "master_custom_user_data" {
  count = var.jenkins_master_instance_count

  template = file("${path.module}/templates/jenkins-master-user-data.tpl")

  vars = {
    project_name                               = "${var.project_name}"
    jenkins_master_name                        = "${var.jenkins_master_name}"
    jenkins_master_username                    = "${var.jenkins_master_username}"
    jenkins_master_password                    = "${var.jenkins_master_password}"
    jenkins_master_use_keycloak                = "${var.jenkins_master_use_keycloak}"
    jenkins_master_keycloak_host               = "${var.jenkins_master_keycloak_host}"
    jenkins_master_keycloak_client_id          = "${var.jenkins_master_keycloak_client_id}"
    jenkins_master_register_exporter_to_consul = "${var.jenkins_master_register_exporter_to_consul}"
  }
}

resource "digitalocean_droplet" "jenkins_master_instance" {
  count = var.jenkins_master_instance_count

  name               = format("%s-%s-%s", var.project_name, var.jenkins_master_name, count.index)
  image              = var.jenkins_master_image_name
  size               = var.jenkins_master_compute_flavor_name
  ssh_keys           = [data.digitalocean_ssh_key.jenkins_master.0.id]
  region             = var.jenkins_master_availability_zone
  vpc_uuid           = data.digitalocean_vpc.jenkins_master_network.0.id
  user_data          = data.template_file.master_user_data.0.rendered
  tags               = concat([var.project_name], split(",", format("consul_cluster_name_%s-%s,project_%s", var.project_name, "consul", var.project_name)))
  private_networking = true
}

resource "null_resource" "jenkins_master_instance_consul_client_leave" {
  count = var.jenkins_master_instance_count

  triggers = {
    private_ip                               = digitalocean_droplet.jenkins_master_instance[count.index].ipv4_address_private
    host_private_key                         = lookup(var.ssh_via_bastion_config, "host_private_key")
    bastion_host                             = lookup(var.ssh_via_bastion_config, "bastion_host")
    bastion_port                             = lookup(var.ssh_via_bastion_config, "bastion_port")
    bastion_ssh_user                         = lookup(var.ssh_via_bastion_config, "bastion_ssh_user")
    bastion_private_key                      = lookup(var.ssh_via_bastion_config, "bastion_private_key")
    execute_on_destroy_jenkins_master_script = join(",", var.execute_on_destroy_jenkins_master_script)
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
    inline     = split(",", self.triggers.execute_on_destroy_jenkins_master_script)
    on_failure = continue
  }

}
