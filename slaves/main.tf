data "http" "generic_user_data_template" {
  url = var.generic_user_data_file_url
}

// ############# Slaves #####################

data "template_file" "slave_user_data" {
  count = var.jenkins_slave_group_instance_count

  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "digitalocean"
    consul_agent_mode         = "client"
    consul_cluster_domain     = var.project_consul_domain
    consul_cluster_datacenter = var.project_consul_datacenter
    consul_cluster_name       = "${var.project_name}-consul"
    do_region                 = var.project_availability_zone
    do_api_token              = var.do_api_token
    enable_logging_graylog    = var.enable_logging_graylog

    pre_configure_script     = <<-EOT
      groupadd jenkins
      useradd -g jenkins jenkins
      mkdir -p /var/run/jenkins/
    EOT
    custom_write_files_block = "${lookup(data.template_file.slave_custom_user_data[count.index], "rendered")}"
    post_configure_script    = <<-EOT
      sh -c /etc/register-slave.sh
    EOT
  }
}

data "template_file" "slave_custom_user_data" {
  count = var.jenkins_slave_group_instance_count

  template = file("${path.module}/templates/jenkins-slave-user-data.tpl")

  vars = {
    jenkins_master_scheme                 = var.jenkins_master_scheme
    jenkins_master_host                   = var.jenkins_master_host
    jenkins_master_port                   = var.jenkins_master_port
    jenkins_node_name                     = format("%s-%s", var.jenkins_slave_group_name, count.index)
    jenkins_slave_description             = format("Dinivas managed Jenkins slave: %s-%s", var.jenkins_slave_group_name, count.index)
    jenkins_slave_nb_executor             = 2
    jenkins_slave_labels                  = join(" ", split(",", var.jenkins_slave_group_labels))
    jenkins_master_username               = var.jenkins_master_username
    jenkins_master_password               = var.jenkins_master_password
    jenkins_slave_wait_for_master_timeout = var.jenkins_slave_wait_for_master_timeout
  }

}

resource "digitalocean_droplet" "slave_group" {
  count = var.jenkins_slave_group_instance_count

  name            = format("%s-%s", var.jenkins_slave_group_name, count.index)
  image_name      = var.jenkins_slave_group_cloud_image
  flavor_name     = var.jenkins_slave_group_cloud_flavor
  key_pair        = var.jenkins_slave_keypair
  user_data       = lookup(data.template_file.slave_user_data[count.index], "rendered")
  security_groups = var.jenkins_slave_security_groups_to_associate
  network {
    name = var.jenkins_slave_network
  }
  availability_zone = var.jenkins_slave_availability_zone

  connection {
    type        = "ssh"
    user        = "centos"
    port        = 22
    host        = self.access_ip_v4
    private_key = lookup(var.ssh_via_bastion_config, "host_private_key")
    agent       = false

    bastion_host        = lookup(var.ssh_via_bastion_config, "bastion_host")
    bastion_port        = 22
    bastion_user        = "centos"
    bastion_private_key = lookup(var.ssh_via_bastion_config, "bastion_private_key")
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      var.execute_on_destroy_jenkins_node_script
    ]
    on_failure = "continue"
  }
}

resource "null_resource" "consul_client_leave" {
  count = var.jenkins_slave_group_instance_count

  triggers = {
    bastion_private_key       = tls_private_key.bastion.private_key_pem
    consul_client_private_key = tls_private_key.project.private_key_pem
    bastion_floating_ip       = local.bastion_floating_ip
    private_ip                = digitalocean_droplet.consul_client[count.index].ipv4_address_private
    bastion_ssh_user          = var.bastion_ssh_user
  }

  connection {
    type        = "ssh"
    user        = "root"
    port        = 22
    host        = self.triggers.private_ip
    private_key = self.triggers.consul_client_private_key
    agent       = false

    bastion_host        = self.triggers.bastion_floating_ip
    bastion_user        = self.triggers.bastion_ssh_user
    bastion_private_key = self.triggers.bastion_private_key
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      var.execute_on_destroy_jenkins_node_script
    ]
    on_failure = continue
  }

}
