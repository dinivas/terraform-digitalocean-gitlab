output "jenkins_master_instance_ids" {
  value = digitalocean_droplet.jenkins_master_instance.*.id
}

output "jenkins_master_network_private_fixed_ip_v4" {
  value = digitalocean_droplet.jenkins_master_instance.*.ipv4_address_private
}
output "jenkins_master_network_public_fixed_ip_v4" {
  value = digitalocean_droplet.jenkins_master_instance.*.ipv4_address
}
