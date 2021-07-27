variable "enable_jenkins_master" {
  type    = string
  default = "1"
}

variable "project_name" {
  description = "The project this Jenkins belong to"
  type        = string
}

variable "jenkins_master_name" {
  description = "The name of the master instance"
  type        = string
}

variable "jenkins_master_instance_count" {
  description = "Number of master instances"
  default     = 1
}

variable "jenkins_master_image_name" {
  description = "The Image name of the master instance"
  type        = string
}

variable "jenkins_master_compute_flavor_name" {
  description = "The Flavor name of the master instance"
  type        = string
}

variable "jenkins_master_keypair_name" {
  description = "The Keypair name of the master instance"
  type        = string
}

variable "jenkins_master_floating_ip_pool" {
  description = "The floating Ip pool of the master instance"
  type        = string
  default     = ""
}

variable "jenkins_master_availability_zone" {
  description = "The availability zone"
  type        = string
  default     = "null"
}

variable "jenkins_master_network" {
  description = "The Network name of the master instance"
  type        = string
}
variable "jenkins_master_security_group_rules" {
  type        = list(map(any))
  default     = []
  description = "The definition os security groups to associate to instance. Only one is allowed"
}

variable "jenkins_master_security_groups_to_associate" {
  type        = list(string)
  default     = []
  description = "List of existing security groups to associate to Jenkins masters."
}

variable "jenkins_master_metadata" {
  default = {}
}

variable "jenkins_external_master_url" {
  description = "The URL of the existing Jenkins master"
  type        = string
  default     = ""
}
variable "jenkins_master_username" {
  description = "The username of the Jenkins master"
  type        = string
  default     = ""
}

variable "jenkins_master_password" {
  description = "The password of the Jenkins master"
  type        = string
  default     = ""
}

variable "jenkins_master_use_keycloak" {
  type        = string
  description = "Delegate Jenkins Auth to Keycloak"
  default     = "0"
}

variable "jenkins_master_keycloak_host" {
  type        = string
  description = "Keycloak host in form host:port"
  default     = ""
}

variable "jenkins_master_keycloak_client_id" {
  type        = string
  description = "Keycloak client_id to use for oauth"
  default     = ""
}

variable "jenkins_master_register_exporter_to_consul" {
  type        = string
  description = "Register Jenkins exporter to consul (default true)"
  default     = "1"
}

variable "jenkins_master_enable_logging_graylog" {
  type = number
  description = "Should graylog output be enable on this host"
  default = 0
}

# Project Consul variables

variable "project_consul_domain" {
  type        = string
  description = "The domain name to use for the Consul cluster"
}

variable "project_consul_datacenter" {
  type        = string
  description = "The datacenter name for the consul cluster"
}

variable "generic_user_data_file_url" {
  type    = string
  default = "https://raw.githubusercontent.com/dinivas/terraform-shared/master/templates/generic-user-data.tpl"
}

variable "execute_on_destroy_jenkins_master_script" {
  type    = string
  default = ""
}

variable "ssh_via_bastion_config" {
  description = "config map used to connect via bastion ssh"
  default     = {}
}

variable "do_api_token" {
  type = string
}