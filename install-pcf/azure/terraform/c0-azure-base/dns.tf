///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
//////// Set Azure DNS references /////////////
///////////////////////////////////////////////

resource "azurerm_dns_zone" "env_dns_zone" {
  name                = "${var.pcf_ert_domain}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
}

resource "azurerm_dns_a_record" "ops_manager_dns" {
  name                = "opsman"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  ttl                 = "60"
  records             = ["${azurerm_public_ip.opsman-public-ip.ip_address}"]
}

resource "azurerm_dns_a_record" "apps" {
  name                = "*.${element(split(".", var.apps_domain), 0)}"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  ttl                 = "60"
  records             = ["${azurerm_public_ip.web-lb-public-ip.ip_address}"]
}

resource "azurerm_dns_a_record" "sys" {
  name                = "*.${element(split(".", var.system_domain), 0)}"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  ttl                 = "60"
  records             = ["${azurerm_public_ip.web-lb-public-ip.ip_address}"]
}

resource "azurerm_dns_a_record" "mysql" {
  name                = "mysql"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  ttl                 = "60"
  records             = ["${azurerm_lb.mysql.private_ip_address}"]
}

resource "azurerm_dns_a_record" "ssh-proxy" {
  name                = "ssh.${element(split(".", var.system_domain), 0)}"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  ttl                 = "60"
  records             = ["${azurerm_public_ip.ssh-proxy-lb-public-ip.ip_address}"]
}


resource "azurerm_dns_a_record" "tcp" {
  name                = "tcp"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  ttl                 = "60"
  records             = ["${azurerm_public_ip.web-lb-public-ip.ip_address}"]
}

resource "azurerm_dns_a_record" "jumpbox" {
  name                = "jumpbox"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  ttl                 = "60"
  records             = ["${azurerm_public_ip.jb-lb-public-ip.ip_address}"]
}
