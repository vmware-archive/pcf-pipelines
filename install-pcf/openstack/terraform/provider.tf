provider "openstack" {
  user_name   = "${var.os_username}"
  tenant_name = "${var.os_tenant_name}"
  password    = "${var.os_password}"
  auth_url    = "${var.os_auth_url}"
  domain_name = "${var.os_domain_name}"
}
