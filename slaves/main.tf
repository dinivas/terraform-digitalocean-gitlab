data "digitalocean_vpc" "jenkins_slave_network" {
  count = var.jenkins_slave_group_instance_count

  name = var.jenkins_slave_network
}
data "http" "generic_user_data_template" {
  url = var.generic_user_data_file_url
}

data "digitalocean_ssh_key" "jenkins_slave" {
  count = var.jenkins_slave_group_instance_count

  name = "${var.project_name}-project-keypair"
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
    do_region                 = var.jenkins_slave_availability_zone
    do_api_token              = var.do_api_token
    enable_logging_graylog    = var.jenkins_slave_group_enable_logging_graylog

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

  name      = format("%s-%s", var.jenkins_slave_group_name, count.index)
  image     = var.jenkins_slave_group_cloud_image
  size      = var.jenkins_slave_group_cloud_flavor
  ssh_keys  = [data.digitalocean_ssh_key.jenkins_slave.0.id]
  region    = var.jenkins_slave_availability_zone
  vpc_uuid  = data.digitalocean_vpc.jenkins_slave_network.0.id
  user_data = lookup(data.template_file.slave_user_data[count.index], "rendered")
  tags      = concat([var.project_name], split(",", format("consul_cluster_name_%s-%s,project_%s", var.project_name, "consul", var.project_name)))

}

resource "null_resource" "slave_group_instance_consul_client_leave" {
  count = var.jenkins_slave_group_instance_count

  triggers = {
    private_ip                             = digitalocean_droplet.slave_group[count.index].ipv4_address_private
    host_private_key                       = lookup(var.ssh_via_bastion_config, "host_private_key")
    bastion_host                           = lookup(var.ssh_via_bastion_config, "bastion_host")
    bastion_port                           = lookup(var.ssh_via_bastion_config, "bastion_port")
    bastion_ssh_user                       = lookup(var.ssh_via_bastion_config, "bastion_ssh_user")
    bastion_private_key                    = lookup(var.ssh_via_bastion_config, "bastion_private_key")
    execute_on_destroy_jenkins_node_script = join(",", var.execute_on_destroy_jenkins_node_script)
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
    inline     = split(",", self.triggers.execute_on_destroy_jenkins_node_script)
    on_failure = continue
  }

}
