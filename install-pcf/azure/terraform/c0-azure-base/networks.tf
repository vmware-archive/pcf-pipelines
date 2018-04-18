///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
//////// Build VNET and Subnets ///////////////
///////////////////////////////////////////////

resource "azurerm_virtual_network" "pcf_virtual_network" {
  name                = "${var.env_name}-virtual-network"
  depends_on          = ["azurerm_resource_group.pcf_resource_group"]
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  address_space       = ["${split(",", var.azure_terraform_vnet_cidr)}"]
  location            = "${var.location}"
}

resource "azurerm_subnet" "opsman_and_director_subnet" {
  name                 = "${var.env_name}-opsman-and-director-subnet"
  resource_group_name  = "${azurerm_resource_group.pcf_resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.pcf_virtual_network.name}"
  address_prefix       = "${var.azure_terraform_subnet_infra_cidr}"
}

resource "azurerm_subnet" "ert_subnet" {
  name                 = "${var.env_name}-ert-subnet"
  resource_group_name  = "${azurerm_resource_group.pcf_resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.pcf_virtual_network.name}"
  address_prefix       = "${var.azure_terraform_subnet_ert_cidr}"
}

resource "azurerm_subnet" "services_subnet" {
  name                 = "${var.env_name}-services-01-subnet"
  resource_group_name  = "${azurerm_resource_group.pcf_resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.pcf_virtual_network.name}"
  address_prefix       = "${var.azure_terraform_subnet_services1_cidr}"
}

resource "azurerm_subnet" "dynamic_services_subnet" {
  name                 = "${var.env_name}-dynamic-services-subnet"
  resource_group_name  = "${azurerm_resource_group.pcf_resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.pcf_virtual_network.name}"
  address_prefix       = "${var.azure_terraform_subnet_dynamic_services_cidr}"
}
