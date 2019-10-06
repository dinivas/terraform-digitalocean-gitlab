variable "os_auth_domain_name" {
  type    = "string"
  default = "default"
}

variable "os_auth_username" {}

variable "os_auth_password" {}

variable "os_auth_url" {}

variable "os_project_id" {}

module "jenkins" {
  source = "../../"

  project_name                                = "dnv"
  enable_jenkins_master                       = "1"
  jenkins_master_name                         = "dnv-jenkins"
  jenkins_master_instance_count               = 1
  jenkins_master_image_name                   = "Dinivas Jenkins Master"
  jenkins_master_compute_flavor_name          = "dinivas.large"
  jenkins_master_keypair_name                 = "dnv"
  jenkins_master_network                      = "dnv-mgmt"
  jenkins_master_subnet                       = "dnv-mgmt-subnet"
  jenkins_master_security_groups_to_associate = ["dnv-common"]
  jenkins_master_floating_ip_pool             = ""
  jenkins_master_availability_zone            = "nova:node03"

  project_consul_domain           = "dinivas"
  project_consul_datacenter       = "gra"

  os_auth_domain_name = "${var.os_auth_domain_name}"
  os_auth_username    = "${var.os_auth_username}"
  os_auth_password    = "${var.os_auth_password}"
  os_auth_url         = "${var.os_auth_url}"
  os_project_id       = "${var.os_project_id}"
}

