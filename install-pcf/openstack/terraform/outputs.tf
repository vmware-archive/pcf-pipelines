output "haproxy_floating_ip" {
  value = "${openstack_networking_floatingip_v2.haproxy_floating_ip.address}"
}
