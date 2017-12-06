output "haproxy_floating_ip" {
  value = "${openstack_networking_floatingip_v2.haproxy_floating_ip.address}"
}

output "opsman_floating_ip" {
  value = "${openstack_networking_floatingip_v2.opsman_floating_ip.address}"
}
