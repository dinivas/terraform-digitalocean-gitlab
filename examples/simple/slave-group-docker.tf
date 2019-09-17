module "jenkins-slave" {
  source = "../../slaves"

  jenkins_master_scheme = "http"
  jenkins_master_host = "localhost"
  jenkins_master_port = "8080"
  jenkins_master_username = "admin"
  jenkins_master_password = "password"
  jenkins_slave_group_name = "dnv-jenkins-slave-docker"
  jenkins_slave_group_labels = "docker, maven"
  jenkins_slave_group_instance_count = 1
  #jenkins_slave_keypair = "${openstack_compute_keypair_v2.keypair.name}"
  jenkins_slave_keypair = "dnv"
  jenkins_slave_network = "dnv-mgmt"
  jenkins_slave_group_cloud_image = "Dinivas Docker Centos7"
  jenkins_slave_group_cloud_flavor   = "dinivas.large"
}