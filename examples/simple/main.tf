variable "project_keycloak_host" {}
variable "do_api_token" {}

module "jenkins" {
  source = "../../"

  project_name                                = "dnv"
  enable_jenkins_master                       = "1"
  jenkins_master_name                         = "dnv-jenkins"
  jenkins_master_instance_count               = 1
  jenkins_master_image_name                   = 88433162 # "Dinivas Jenkins Master 2021-07-23"
  jenkins_master_compute_flavor_name          = "s-2vcpu-4gb"
  jenkins_master_keypair_name                 = "dnv-project-keypair"
  jenkins_master_network                      = "59293df8-dd0c-449d-908c-39dce7b83262"
  jenkins_master_security_groups_to_associate = ["dnv-common"]
  jenkins_master_floating_ip_pool             = ""
  jenkins_master_availability_zone            = "fra1"

  project_consul_domain       = "dinivas.io"
  project_consul_datacenter   = "fra1"
  jenkins_master_use_keycloak = 1

  jenkins_master_keycloak_host               = var.project_keycloak_host
  jenkins_master_keycloak_client_id          = "jenkins"
  jenkins_master_register_exporter_to_consul = 1
  do_api_token                               = var.do_api_token
}

