resource "openstack_networking_network_v2" "infra_net" {
  name = "${var.prefix}-infra-net"
  region = "${var.os_region}"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "infra_subnet" {
  network_id = "${openstack_networking_network_v2.infra_net.id}"
  region = "${var.os_region}"
  cidr = "${var.infra_subnet_cidr}"
  ip_version = 4
  enable_dhcp = true
  dns_nameservers = [
    "${var.infra_dns}"
  ]
}

resource "openstack_networking_network_v2" "ert_net" {
  name = "${var.prefix}-ert-net"
  region = "${var.os_region}"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "ert_subnet" {
  network_id = "${openstack_networking_network_v2.ert_net.id}"
  region = "${var.os_region}"
  cidr = "${var.ert_subnet_cidr}"
  ip_version = 4
  enable_dhcp = true
  dns_nameservers = [
    "${var.ert_dns}"
  ]
}

resource "openstack_networking_network_v2" "services_net" {
  name = "${var.prefix}-services-net"
  region = "${var.os_region}"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "services_subnet" {
  network_id = "${openstack_networking_network_v2.services_net.id}"
  region = "${var.os_region}"
  cidr = "${var.services_subnet_cidr}"
  ip_version = 4
  enable_dhcp = true
  dns_nameservers = [
    "${var.services_dns}"
  ]
}

resource "openstack_networking_network_v2" "dynamic_services_net" {
  name = "${var.prefix}-dynamic-services-net"
  region = "${var.os_region}"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "dynamic_services_subnet" {
  network_id = "${openstack_networking_network_v2.dynamic_services_net.id}"
  region = "${var.os_region}"
  cidr = "${var.dynamic_services_subnet_cidr}"
  ip_version = 4
  enable_dhcp = true
  dns_nameservers = [
    "${var.dynamic_services_dns}"
  ]
}

resource "openstack_networking_router_v2" "internal_router" {
  region = "${var.os_region}"
  name = "${var.prefix}-router"
  external_gateway = "${var.external_network_id}"
  admin_state_up = "true"
}

resource "openstack_networking_router_interface_v2" "infra_interface" {
  region = "${var.os_region}"
  router_id = "${openstack_networking_router_v2.internal_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.infra_subnet.id}"
}

resource "openstack_networking_router_interface_v2" "ert_interface" {
  region = "${var.os_region}"
  router_id = "${openstack_networking_router_v2.internal_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.ert_subnet.id}"
}

resource "openstack_networking_router_interface_v2" "services_interface" {
  region = "${var.os_region}"
  router_id = "${openstack_networking_router_v2.internal_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.services_subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dynamic_services_interface" {
  region = "${var.os_region}"
  router_id = "${openstack_networking_router_v2.internal_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.dynamic_services_subnet.id}"
}

resource "openstack_networking_floatingip_v2" "haproxy_floating_ip" {
  pool = "${var.external_network}"
}
