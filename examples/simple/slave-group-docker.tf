module "jenkins-slave" {
  source = "../../slaves"

  project_name                               = "dnv"
  project_consul_domain                      = "dinivas.io"
  project_consul_datacenter                  = "fra1"
  jenkins_master_scheme                      = "http"
  jenkins_master_host                        = "dnv-jenkins-0"
  jenkins_master_port                        = "8080"
  jenkins_master_username                    = "admin"
  jenkins_master_password                    = "11713d028b08821e048913e1f1a3663d5c" # should be the api token when using keycloak
  jenkins_slave_group_name                   = "dnv-jenkins-slave-docker"
  jenkins_slave_group_labels                 = "docker, maven"
  jenkins_slave_group_instance_count         = 0
  jenkins_slave_keypair                      = "dnv-project-keypair"
  jenkins_slave_network                      = "dnv-mgmt"
  jenkins_slave_group_cloud_image            = 87735628
  jenkins_slave_group_cloud_flavor           = "s-1vcpu-2gb"
  jenkins_slave_security_groups_to_associate = ["dnv-common"]
  jenkins_slave_availability_zone            = "fra1"
  ssh_via_bastion_config                     = var.ssh_via_bastion_config

  do_api_token = var.do_api_token
}
