# resource "openstack_compute_keypair_v2" "keypair" {
#   name = "my-keypair"
# }

module "jenkins" {
  source = "../../"

  enable_jenkins_master              = "1"
  jenkins_master_name                = "dnv-jenkins"
  jenkins_master_instance_count      = 1
  jenkins_master_image_name          = "Jenkins Master"
  jenkins_master_compute_flavor_name = "dinivas.large"
  #jenkins_master_keypair_name        = "${openstack_compute_keypair_v2.keypair.name}"
  jenkins_master_keypair_name     = "dnv"
  jenkins_master_network          = "dnv-mgmt"
  jenkins_master_subnet           = "dnv-mgmt-subnet"
  jenkins_master_floating_ip_pool = "public"
}

