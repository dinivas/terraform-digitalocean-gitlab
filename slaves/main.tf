// ############# Slaves #####################

data "template_file" "user_data" {
  count = "${var.jenkins_slave_group_instance_count}"

  template = "${file("${path.module}/template/user-data.tpl")}"

  vars = {
    jenkins_master_scheme                    = "${var.jenkins_master_scheme}"
    jenkins_master_host                    = "${var.jenkins_master_host}"
    jenkins_master_port                    = "${var.jenkins_master_port}"
    jenkins_node_name                     = "${format("%s-%s", var.jenkins_slave_group_name, count.index)}"
    jenkins_slave_description             = "${format("Dinivas managed Jenkins slave: %s-%s", var.jenkins_slave_group_name, count.index)}"
    jenkins_slave_nb_executor             = 2
    jenkins_slave_labels                  = "${join(" ", split(",", var.jenkins_slave_group_labels))}"
    jenkins_master_username               = "${var.jenkins_master_username}"
    jenkins_master_password               = "${var.jenkins_master_password}"
    jenkins_slave_wait_for_master_timeout = "${var.jenkins_slave_wait_for_master_timeout}"
  }
}

resource "openstack_compute_instance_v2" "slave_group" {
  count = "${var.jenkins_slave_group_instance_count}"

  name            = "${format("%s-%s", var.jenkins_slave_group_name, count.index)}"
  image_name      = "${var.jenkins_slave_group_cloud_image}"
  flavor_name     = "${var.jenkins_slave_group_cloud_flavor}"
  key_pair        = "${var.jenkins_slave_keypair}"
  user_data       = "${lookup(data.template_file.user_data[count.index], "rendered")}"
  security_groups = "${var.jenkins_slave_security_groups_to_associate}"
  network {
    name = "${var.jenkins_slave_network}"
  }
  availability_zone = "${var.jenkins_slave_availability_zone}"
}
