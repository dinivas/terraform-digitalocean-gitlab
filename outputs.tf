output "gitlab_server_instance_ids" {
  value = digitalocean_droplet.gitlab_server_instance.*.id
}

output "gitlab_server_network_private_fixed_ip_v4" {
  value = digitalocean_droplet.gitlab_server_instance.*.ipv4_address_private
}
output "gitlab_server_network_public_fixed_ip_v4" {
  value = digitalocean_droplet.gitlab_server_instance.*.ipv4_address
}
