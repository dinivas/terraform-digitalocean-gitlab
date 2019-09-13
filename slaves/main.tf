// ############# Slaves #####################


// Source add_slave groovy script

data "template_file" "add_slave_groovy" {
  template = "${file("${path.module}/template/add_slave.groovy.tpl")}"

  vars = {
    jenkins_master_url        = "${var.jenkins_master_url}"
    jenkins_node_name         = "${var.jenkins_slave_group_name}"
    jenkins_slave_description = "${var.jenkins_slave_group_name}"
    jenkins_slave_nb_executor = 2
    jenkins_slave_labels      = "${join(" ",split(",",var.jenkins_slave_group_labels))}"
  }
}

data "template_file" "jenkins_slave_service" {
  template = "${file("${path.module}/template/jenkins-slave.service.tpl")}"

  vars = {
    jenkins_master_url        = "${var.jenkins_master_url}"
    jenkins_node_name         = "${var.jenkins_slave_group_name}"
  }
}

data "template_file" "register_slave_sh" {
  template = "${file("${path.module}/template/register-slave.sh.tpl")}"

  vars = {
    jenkins_master_url        = "${var.jenkins_master_url}"
    jenkins_node_name         = "${var.jenkins_slave_group_name}"
    jenkins_master_username = "${var.jenkins_master_username}"
    jenkins_master_password = "${var.jenkins_master_password}"
  }
}


data "template_file" "user_data" {
  template = "${file("${path.module}/template/user-data.tpl")}"

  vars = {
    jenkins_master_url        = "${var.jenkins_master_url}"
    jenkins_node_name         = "${var.jenkins_slave_group_name}"
    jenkins_slave_description = "${var.jenkins_slave_group_name}"
    jenkins_slave_nb_executor = 2
    jenkins_slave_labels      = "${var.jenkins_slave_group_labels}"
    jenkins_master_username = "${var.jenkins_master_username}"
    jenkins_master_password = "${var.jenkins_master_password}"
  }
}

resource "openstack_compute_instance_v2" "slave_group" {
  count = "${var.jenkins_slave_group_instance_count}"

  name            = "${format("%s-%s", var.jenkins_slave_group_name, count.index)}"
  image_name      = "${var.jenkins_slave_group_cloud_image}"
  flavor_name     = "${var.jenkins_slave_group_cloud_flavor}"
  key_pair        = "${var.jenkins_slave_keypair}"
  user_data       = "${data.template_file.user_data.rendered}"
  security_groups = "${var.jenkins_slave_security_groups_to_associate}"
  network {
    name = "${var.jenkins_slave_network}"
  }

  provisioner "file" {
    content      = "${data.template_file.register_slave_sh.rendered}"
    destination = "/etc/register-slave.sh"
  }

  provisioner "file" {
    content      = "${data.template_file.add_slave_groovy.rendered}"
    destination = "/var/run/jenkins/add_slave.groovy"
  }

  provisioner "file" {
    content      = "${data.template_file.jenkins_slave_service.rendered}"
    destination = "/etc/systemd/system/jenkins-slave.service"
  }

  provisioner "local-exec" {
    command = "sh -c /etc/register-slave.sh"
  }
}
