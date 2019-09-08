data "openstack_networking_network_v2" "jenkins_master_network" {
  count = "${var.enable_jenkins_master}"

  name = "${var.jenkins_master_network}"
}

data "openstack_networking_subnet_v2" "jenkins_master_subnet" {
  count = "${var.enable_jenkins_master}"

  name = "${var.jenkins_master_subnet}"
}

module "jenkins_master_instance" {
  source = "github.com/dinivas/terraform-openstack-instance"

  instance_name                 = "${var.jenkins_master_name}-master"
  instance_count                = "${var.jenkins_master_instance_count}"
  image_name                    = "${var.jenkins_master_image_name}"
  flavor_name                   = "${var.jenkins_master_compute_flavor_name}"
  keypair                       = "${var.jenkins_master_keypair_name}"
  network_ids                   = ["${data.openstack_networking_network_v2.jenkins_master_network.0.id}"]
  subnet_ids                    = ["${data.openstack_networking_subnet_v2.jenkins_master_subnet.*.id}"]
  instance_security_group_name  = "${var.jenkins_master_name}-sg"
  instance_security_group_rules = "${var.jenkins_master_security_group_rules}"
  metadata                      = "${var.jenkins_master_metadata}"
  enabled                       = "${var.enable_jenkins_master}"

  //security_groups_to_associate  = ["${var.jenkins_master_security_groups_to_associate}"]
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
