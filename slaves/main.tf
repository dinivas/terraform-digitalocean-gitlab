// ############# Slaves #####################


resource "openstack_compute_instance_v2" "slave_group" {
  count = "${var.jenkins_slave_group_instance_count}"

  name            = "${format("%s-%s", var.jenkins_slave_group_name, count.index)}"
  image_name      = "${var.jenkins_slave_group_cloud_image}"
  flavor_name     = "${var.jenkins_slave_group_cloud_flavor}"
  key_pair        = "${var.jenkins_slave_keypair}"
  security_groups = ["default"]
  network {
    name = "${var.jenkins_slave_network}"
  }
}
