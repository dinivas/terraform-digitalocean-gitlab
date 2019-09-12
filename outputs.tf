output "jenkins_master_instance_ids" {
  value = "${module.jenkins_master_instance.ids}"
}

output "jenkins_master_floating_ip" {
  value       = "${openstack_networking_floatingip_v2.jenkins_master_floatingip.0.address}"
  description = "The floating ips bind to Jenkins master"
}
