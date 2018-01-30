resource "openstack_compute_instance_v2" "opsman" {
  name            = "${var.prefix}-opsman"
  image_name      = "${var.opsman_image_name}"
  flavor_name     = "${var.opsman_flavor}"
  key_pair        = "${openstack_compute_keypair_v2.opsman_keypair.name}"
  security_groups = [
    "${openstack_compute_secgroup_v2.main_security_group.name}"
  ]

  network {
    name = "${openstack_networking_network_v2.infra_net.name}"
    fixed_ip_v4 = "${var.opsman_fixed_ip}"
  }
}

resource "openstack_compute_keypair_v2" "opsman_keypair" {
  name       = "${var.prefix}-opsman-keypair"
  public_key = "${var.opsman_public_key}"
}

resource "openstack_networking_floatingip_v2" "opsman_floating_ip" {
  pool = "${var.external_network}"
}

resource "openstack_compute_floatingip_associate_v2" "opsman_floating_ip_association" {
  floating_ip = "${openstack_networking_floatingip_v2.opsman_floating_ip.address}"
  instance_id = "${openstack_compute_instance_v2.opsman.id}"
}

resource "openstack_blockstorage_volume_v2" "opsman_volume" {
  region      = "${var.os_region}"
  name        = "${var.prefix}-opsman-volume"
  size        = "${ceil(var.opsman_volume_size)}"
}

resource "openstack_compute_volume_attach_v2" "opsman_volume_attachment" {
  instance_id = "${openstack_compute_instance_v2.opsman.id}"
  volume_id   = "${openstack_blockstorage_volume_v2.opsman_volume.id}"
}
