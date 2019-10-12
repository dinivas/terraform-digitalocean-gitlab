module "jenkins-slave" {
  source = "../../slaves"

  project_name                               = "dnv"
  project_consul_domain                      = "dinivas"
  project_consul_datacenter                  = "gra"
  jenkins_master_scheme                      = "http"
  jenkins_master_host                        = "localhost"
  jenkins_master_port                        = "8080"
  jenkins_master_username                    = "admin"
  jenkins_master_password                    = "password"
  jenkins_slave_group_name                   = "dnv-jenkins-slave-docker"
  jenkins_slave_group_labels                 = "docker, maven"
  jenkins_slave_group_instance_count         = 1
  jenkins_slave_keypair                      = "dnv"
  jenkins_slave_network                      = "dnv-mgmt"
  jenkins_slave_group_cloud_image            = "Dinivas Builder"
  jenkins_slave_group_cloud_flavor           = "dinivas.large"
  jenkins_slave_security_groups_to_associate = ["dnv-common"]
  jenkins_slave_availability_zone            = "nova:node03"

  os_auth_domain_name = "${var.os_auth_domain_name}"
  os_auth_username    = "${var.os_auth_username}"
  os_auth_password    = "${var.os_auth_password}"
  os_auth_url         = "${var.os_auth_url}"
  os_project_id       = "${var.os_project_id}"
}
