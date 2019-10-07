variable "project_name" {
  description = "The project this Jenkins slave belong to"
  type        = "string"
}

variable "jenkins_slave_group_name" {
  type        = "string"
  description = "The slave group name"
}

variable "jenkins_master_scheme" {
  type        = "string"
  description = "The Jenkins master URL scheme"
}

variable "jenkins_master_host" {
  type        = "string"
  description = "The Jenkins master host"
}

variable "jenkins_master_port" {
  type        = "string"
  description = "The Jenkins master port"
  default = "8080"
}

variable "jenkins_master_username" {
  type        = "string"
  description = "The Jenkins master username"
}

variable "jenkins_master_password" {
  type        = "string"
  description = "The Jenkins master password"
}
variable "jenkins_slave_group_labels" {
  type        = "string"
  description = "The slave group labels separated by ,"
}

variable "jenkins_slave_availability_zone" {
  description = "The availability zone"
  type        = "string"
}

variable "jenkins_slave_group_instance_count" {
  type        = "string"
  description = "The slave group instance count"
}
variable "jenkins_slave_group_cloud_image" {
  type        = "string"
  description = "The slave group image name"
}

variable "jenkins_slave_group_cloud_flavor" {
  type        = "string"
  description = "The slave group flavor name"
}

variable "jenkins_slave_network" {
  type        = "string"
  description = "The slave group network"
}

variable "jenkins_slave_keypair" {
  type        = "string"
  description = "The slave group keypair to use"
}

variable "jenkins_slave_security_groups_to_associate" {
  type        = list(string)
  default     = []
  description = "List of existing security groups to associate to Jenkins slave."
}

variable "jenkins_slave_wait_for_master_timeout" {
  type        = "string"
  description = "Timeout in second to wait for Jenkins master to be accessible"
  default     = "600" # 10min
}

# Project Consul variables

variable "project_consul_domain" {
  type        = "string"
  description = "The domain name to use for the Consul cluster"
}

variable "project_consul_datacenter" {
  type        = "string"
  description = "The datacenter name for the consul cluster"
}

# Auth variables used by consul

variable "os_auth_domain_name" {
  type    = "string"
  default = "default"
}

variable "os_auth_username" {
  type = "string"
}

variable "os_auth_password" {
  type = "string"
}

variable "os_auth_url" {
  type = "string"
}

variable "os_project_id" {
  type = "string"
}