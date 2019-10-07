data "openstack_networking_network_v2" "jenkins_master_network" {
  count = "${var.enable_jenkins_master}"

  name = "${var.jenkins_master_network}"
}

data "openstack_networking_subnet_v2" "jenkins_master_subnet" {
  count = "${var.enable_jenkins_master}"

  name = "${var.jenkins_master_subnet}"
}


data "template_file" "master_user_data" {
  count = "${var.jenkins_master_instance_count}"

  template = "${file("${path.module}/template/user-data.tpl")}"

  vars = {
    project_name                               = "${var.project_name}"
    jenkins_master_name                        = "${var.jenkins_master_name}"
    jenkins_master_use_keycloak                = "${var.jenkins_master_use_keycloak}"
    jenkins_master_keycloak_host               = "${var.jenkins_master_keycloak_host}"
    jenkins_master_keycloak_client_id          = "${var.jenkins_master_keycloak_client_id}"
    jenkins_master_register_exporter_to_consul = "${var.jenkins_master_register_exporter_to_consul}"
    consul_agent_mode                          = "client"
    consul_cluster_domain                      = "${var.project_consul_domain}"
    consul_cluster_datacenter                  = "${var.project_consul_datacenter}"
    consul_cluster_name                        = "${var.project_name}-consul"
    os_auth_domain_name                        = "${var.os_auth_domain_name}"
    os_auth_username                           = "${var.os_auth_username}"
    os_auth_password                           = "${var.os_auth_password}"
    os_auth_url                                = "${var.os_auth_url}"
    os_project_id                              = "${var.os_project_id}"
  }
}

module "jenkins_master_instance" {
  source = "github.com/dinivas/terraform-openstack-instance"

  instance_name                 = "${var.jenkins_master_name}"
  instance_count                = "${var.jenkins_master_instance_count}"
  image_name                    = "${var.jenkins_master_image_name}"
  flavor_name                   = "${var.jenkins_master_compute_flavor_name}"
  keypair                       = "${var.jenkins_master_keypair_name}"
  network_ids                   = ["${data.openstack_networking_network_v2.jenkins_master_network.0.id}"]
  subnet_ids                    = ["${data.openstack_networking_subnet_v2.jenkins_master_subnet.*.id}"]
  instance_security_group_name  = "${var.jenkins_master_name}-sg"
  instance_security_group_rules = "${var.jenkins_master_security_group_rules}"
  security_groups_to_associate  = "${var.jenkins_master_security_groups_to_associate}"
  user_data                     = "${data.template_file.master_user_data.0.rendered}"
  metadata                      = "${merge(var.jenkins_master_metadata, map("consul_cluster_name", format("%s-%s", var.project_name, "consul")))}"
  enabled                       = "${var.enable_jenkins_master}"
  availability_zone             = "${var.jenkins_master_availability_zone}"

}

// Conditional floating ip
resource "openstack_networking_floatingip_v2" "jenkins_master_floatingip" {
  count = "${var.jenkins_master_floating_ip_pool != "" ? var.enable_jenkins_master * 1 : 0}"

  pool = "${var.jenkins_master_floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "jenkins_master_floatingip_associate" {
  count = "${var.jenkins_master_floating_ip_pool != "" ? var.enable_jenkins_master * var.jenkins_master_instance_count : 0}"

  floating_ip           = "${lookup(openstack_networking_floatingip_v2.jenkins_master_floatingip[count.index], "address")}"
  instance_id           = "${module.jenkins_master_instance.ids[count.index]}"
  fixed_ip              = "${module.jenkins_master_instance.network_fixed_ip_v4[count.index]}"
  wait_until_associated = true
}
