output "jenkins_master_instance_ids" {
  description = "Jenkins master instance ids"
  value       = "${module.jenkins.jenkins_master_instance_ids}"
}
