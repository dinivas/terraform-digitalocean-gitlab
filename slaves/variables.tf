variable "jenkins_slave_group_name" {
  type        = "string"
  description = "The slave group name"
}

variable "jenkins_master_url" {
  type        = "string"
  description = "The Jenkins master URL"
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
