variable "project_name" {
  description = "The project this Gitlab runner belong to"
  type        = string
}

variable "gitlab_runner_group_name" {
  type        = string
  description = "The Runner group name"
}

variable "gitlab_runner_group_gitlab_url" {
  type        = string
  description = "The Gitlab URL"
}

variable "gitlab_runner_group_gitlab_token" {
  type        = string
  description = "The Gitlab token"
}

variable "gitlab_runner_group_executor" {
  type        = string
  description = "The Gitlab runner executor"
  default     = "docker"
}

variable "gitlab_runner_group_docker_image" {
  type        = string
  description = "The Runner docker executor image"
  default     = "alpine"
}
variable "gitlab_runner_group_tags" {
  type        = string
  description = "The runner group tags separated by ,"
}

variable "gitlab_runner_availability_zone" {
  description = "The availability zone"
  type        = string
}

variable "gitlab_runner_group_instance_count" {
  type        = string
  description = "The runner group instance count"
}
variable "gitlab_runner_group_cloud_image" {
  type        = string
  description = "The runner group image name"
}

variable "gitlab_runner_group_cloud_flavor" {
  type        = string
  description = "The runner group flavor name"
}

variable "gitlab_runner_group_enable_logging_graylog" {
  type        = number
  description = "Should graylog output be enable on this host"
  default     = 0
}

variable "gitlab_runner_network" {
  type        = string
  description = "The VPC id"
}

variable "gitlab_runner_keypair" {
  type        = string
  description = "The runner group keypair to use"
}

variable "gitlab_runner_security_groups_to_associate" {
  type        = list(string)
  default     = []
  description = "List of existing security groups to associate to Jenkins runner."
}

variable "gitlab_runner_group_prometheus_listen_address" {
  type        = string
  description = "Prometheus listen adress"
  default     = ":9252"
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

variable "execute_on_destroy_gitlab_runner_script" {
  type        = list(string)
  description = "List of inline commands called before instance destruction"
  default     = ["gitlab-runner register -c /etc/gitlab-runner/config.toml", "consul leave"]
}

variable "ssh_via_bastion_config" {
  description = "config map used to connect via bastion ssh"
  default     = {}
}

variable "host_private_key" {}
variable "bastion_private_key" {}
