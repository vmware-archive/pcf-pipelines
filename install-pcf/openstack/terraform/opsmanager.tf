resource "openstack_compute_instance_v2" "opsman" {
  name            = "${var.prefix}-opsman"
  image_id        = "${var.opsman_image_name}"
  flavor_id       = "3"
  key_pair        = "${openstack_compute_keypair_v2.opsman_keypair.name}"
  security_groups = [
    "${openstack_compute_secgroup_v2.main_security_group.name}"
  ]

  network {
    name = "${openstack_networking_network_v2.infra_net.name}"
  }
}

resource "openstack_compute_keypair_v2" "opsman_keypair" {
  name       = "${var.prefix}-opsman-keypair"
  public_key = "${var.opsman_public_key}"
}

