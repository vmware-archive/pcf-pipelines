resource "openstack_compute_secgroup_v2" "main_security_group" {
  name = "${var.prefix}"
  description = "${var.prefix} security group"
  region = "${var.os_region}"

  rule {
    ip_protocol = "tcp"
    from_port = "1"
    to_port = "65535"
    cidr = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "udp"
    from_port = "1"
    to_port = "65535"
    cidr = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "icmp"
    from_port = "-1"
    to_port = "-1"
    cidr = "0.0.0.0/0"
  }
}

