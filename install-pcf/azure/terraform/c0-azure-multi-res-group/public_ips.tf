///////////======================//////////////
//// Addresses      =============//////////////
///////////======================//////////////

resource "azurerm_public_ip" "tcp-lb-public-ip" {
  name                         = "${var.env_name}-tcp-lb-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.azure_multi_resgroup_network}"
  public_ip_address_allocation = "static"
}

data "azurerm_public_ip" "tcp-lb-public-ip" {
  name                = "${var.env_name}-tcp-lb-public-ip"
  resource_group_name = "${var.azure_multi_resgroup_network}"
  depends_on          = ["azurerm_public_ip.tcp-lb-public-ip"]
}

resource "azurerm_public_ip" "web-lb-public-ip" {
  name                         = "${var.env_name}-web-lb-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.azure_multi_resgroup_network}"
  public_ip_address_allocation = "static"
}

data "azurerm_public_ip" "web-lb-public-ip" {
  name                = "${var.env_name}-web-lb-public-ip"
  resource_group_name = "${var.azure_multi_resgroup_network}"
  depends_on          = ["azurerm_public_ip.web-lb-public-ip"]
}

resource "azurerm_public_ip" "opsman-public-ip" {
  name                         = "${var.env_name}-opsman-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.azure_multi_resgroup_network}"
  public_ip_address_allocation = "static"
}

data "azurerm_public_ip" "opsman-public-ip" {
  name                = "${var.env_name}-opsman-public-ip"
  resource_group_name = "${var.azure_multi_resgroup_network}"
  depends_on          = ["azurerm_public_ip.opsman-public-ip"]
}

resource "azurerm_public_ip" "ssh-proxy-lb-public-ip" {
  name                         = "${var.env_name}-ssh-proxy-lb-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.azure_multi_resgroup_network}"
  public_ip_address_allocation = "static"
}

data "azurerm_public_ip" "ssh-lb-public-ip" {
  name                = "${var.env_name}-ssh-lb-public-ip"
  resource_group_name = "${var.azure_multi_resgroup_network}"
  depends_on          = ["azurerm_public_ip.ssh-lb-public-ip"]
}

resource "azurerm_public_ip" "jb-lb-public-ip" {
  name                         = "${var.env_name}-jb-lb-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.azure_multi_resgroup_network}"
  public_ip_address_allocation = "static"
}

data "azurerm_public_ip" "jb-lb-public-ip" {
  name                = "${var.env_name}-jb-lb-public-ip"
  resource_group_name = "${var.azure_multi_resgroup_network}"
  depends_on          = ["azurerm_public_ip.jb-lb-public-ip"]
}