module "jenkins-slave1" {
  source = "../../slaves"

  jenkins_master_url = "http://localhost:8080"
  jenkins_master_username = "admin"
  jenkins_master_password = "password"
  jenkins_slave_group_name = "slave-maven"
  jenkins_slave_group_labels = "docker, maven"
  jenkins_slave_group_instance_count = 3
  #jenkins_slave_keypair = "${openstack_compute_keypair_v2.keypair.name}"
  jenkins_slave_keypair = "dnv"
  jenkins_slave_network = "dnv-mgmt"
  jenkins_slave_group_cloud_image = "Dinivas Base Centos7"
  jenkins_slave_group_cloud_flavor   = "dinivas.medium"
}