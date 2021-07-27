variable "project_name" {
  description = "The project this Jenkins slave belong to"
  type        = string
}

variable "jenkins_slave_group_name" {
  type        = string
  description = "The slave group name"
}

variable "jenkins_master_scheme" {
  type        = string
  description = "The Jenkins master URL scheme"
}

variable "jenkins_master_host" {
  type        = string
  description = "The Jenkins master host"
}

variable "jenkins_master_port" {
  type        = string
  description = "The Jenkins master port"
  default     = "8080"
}

variable "jenkins_master_username" {
  type        = string
  description = "The Jenkins master username"
}

variable "jenkins_master_password" {
  type        = string
  description = "The Jenkins master password"
}
variable "jenkins_slave_group_labels" {
  type        = string
  description = "The slave group labels separated by ,"
}

variable "jenkins_slave_availability_zone" {
  description = "The availability zone"
  type        = string
}

variable "jenkins_slave_group_instance_count" {
  type        = string
  description = "The slave group instance count"
}
variable "jenkins_slave_group_cloud_image" {
  type        = string
  description = "The slave group image name"
}

variable "jenkins_slave_group_cloud_flavor" {
  type        = string
  description = "The slave group flavor name"
}

variable "jenkins_slave_group_enable_logging_graylog" {
  type        = number
  description = "Should graylog output be enable on this host"
  default     = 0
}

variable "jenkins_slave_network" {
  type        = string
  description = "The VPC id"
}

variable "jenkins_slave_keypair" {
  type        = string
  description = "The slave group keypair to use"
}

variable "jenkins_slave_security_groups_to_associate" {
  type        = list(string)
  default     = []
  description = "List of existing security groups to associate to Jenkins slave."
}

variable "jenkins_slave_wait_for_master_timeout" {
  type        = string
  description = "Timeout in second to wait for Jenkins master to be accessible"
  default     = "600" # 10min
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

# Auth variables used by consul
variable "do_api_token" {
  type = string
}

variable "generic_user_data_file_url" {
  type    = string
  default = "https://raw.githubusercontent.com/dinivas/terraform-shared/master/templates/generic-user-data.tpl"
}

variable "execute_on_destroy_jenkins_node_script" {
  type    = string
  default = ""
}

variable "ssh_via_bastion_config" {
  description = "config map used to connect via bastion ssh"
  default     = {}
}
