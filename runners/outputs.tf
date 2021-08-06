output "gitlab_runner_instance_ids" {
  value = digitalocean_droplet.gitlab_runner.*.id
}

output "gitlab_runner_network_private_fixed_ip_v4" {
  value = digitalocean_droplet.gitlab_runner.*.ipv4_address_private
}
output "gitlab_runner_network_public_fixed_ip_v4" {
  value = digitalocean_droplet.gitlab_runner.*.ipv4_address
}
