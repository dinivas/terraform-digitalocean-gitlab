module "jenkins-slave" {
  source = "../../slaves"

  project_name                               = "dnv"
  project_consul_domain                      = "dinivas.io"
  project_consul_datacenter                  = "fra1"
  jenkins_master_scheme                      = "http"
  jenkins_master_host                        = "dnv-dnv-jenkins-0"
  jenkins_master_port                        = "8080"
  jenkins_master_username                    = "admin"
  jenkins_master_password                    = "110ecce56ca6995d13aed6535e62974777" # should be the api token when using keycloak
  jenkins_slave_group_name                   = "dnv-jenkins-slave-docker"
  jenkins_slave_group_labels                 = "docker, maven"
  jenkins_slave_group_instance_count         = 2
  jenkins_slave_keypair                      = "dnv-project-keypair"
  jenkins_slave_network                      = "59293df8-dd0c-449d-908c-39dce7b83262"
  jenkins_slave_group_cloud_image            = 87735628
  jenkins_slave_group_cloud_flavor           = "s-1vcpu-2gb"
  jenkins_slave_security_groups_to_associate = ["dnv-common"]
  jenkins_slave_availability_zone            = "fra1"

  do_api_token                               = var.do_api_token
}
