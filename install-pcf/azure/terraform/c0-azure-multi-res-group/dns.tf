///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
//////// Set Azure DNS references /////////////
///////////////////////////////////////////////

resource "azurerm_dns_zone" "env_dns_zone" {
  name                = "${var.pcf_ert_domain}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
}

resource "azurerm_dns_a_record" "ops_manager_dns" {
  name                = "opsman"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  ttl                 = "60"
  records             = ["${var.pub_ip_opsman_vm}"]
}

resource "azurerm_dns_a_record" "apps" {
  name                = "*.${element(split(".", var.apps_domain), 0)}"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  ttl                 = "60"
  records             = ["${var.pub_ip_pcf_lb}"]
}

resource "azurerm_dns_a_record" "sys" {
  name                = "*.${element(split(".", var.system_domain), 0)}"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  ttl                 = "60"
  records             = ["${var.pub_ip_pcf_lb}"]
}

resource "azurerm_dns_a_record" "mysql" {
  name                = "mysql-proxy-lb.${element(split(".", var.system_domain), 0)}"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  ttl                 = "60"
  records             = ["${var.priv_ip_mysql_lb}"]
}

resource "azurerm_dns_a_record" "ssh-proxy" {
  name                = "ssh.${element(split(".", var.system_domain), 0)}"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  ttl                 = "60"
  records             = ["${var.pub_ip_ssh_proxy_lb}"]
}


resource "azurerm_dns_a_record" "tcp" {
  name                = "tcp"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  ttl                 = "60"
  records             = ["${var.pub_ip_pcf_lb}"]
}

resource "azurerm_dns_a_record" "jumpbox" {
  name                = "jumpbox"
  zone_name           = "${azurerm_dns_zone.env_dns_zone.name}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  ttl                 = "60"
  records             = ["${var.pub_ip_jumpbox_vm}"]
}
