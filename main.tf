data "digitalocean_vpc" "jenkins_master_network" {
  count = var.enable_jenkins_master

  id = var.jenkins_master_network
}


data "http" "generic_user_data_template" {
  url = var.generic_user_data_file_url
}

data "template_file" "master_user_data" {
  count = var.jenkins_master_instance_count

  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "digital"
    consul_agent_mode         = "client"
    consul_cluster_domain     = "${var.project_consul_domain}"
    consul_cluster_datacenter = "${var.project_consul_datacenter}"
    consul_cluster_name       = "${var.project_name}-consul"
    do_region                 = var.project_availability_zone
    do_api_token              = var.do_api_token
    enable_logging_graylog    = var.enable_logging_graylog

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

module "jenkins_master_instance" {
  source = "github.com/dinivas/terraform-digital-instance"

  project_name              = var.project_name
  instance_count            = var.jenkins_master_instance_count
  instance_name             = var.jenkins_master_name
  project_availability_zone = var.jenkins_master_availability_zone
  instance_vpc_id           = data.digitalocean_vpc.jenkins_master_network.0.id
  instance_image_name       = var.jenkins_master_image_name
  instance_flavor_name      = var.jenkins_master_compute_flavor_name
  instance_ssh_key_id       = var.jenkins_master_keypair_name
  project_consul_domain     = var.project_consul_domain
  project_consul_datacenter = var.project_consul_datacenter
  enable_logging_graylog    = var.jenkins_master_enable_logging_graylog
  do_api_token              = var.do_api_token
}

// Conditional floating ip
resource "digitalocean_floating_ip" "jenkins_master_floatingip" {
  count = var.jenkins_master_floating_ip_pool != "" ? var.enable_jenkins_master * var.jenkins_master_instance_count : 0

  droplet_id = module.jenkins_master_instance.ids[count.index]
  region     = var.jenkins_master_availability_zone
}
