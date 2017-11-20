///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
//////// Set Azure Storage Accts //////////////
///////////////////////////////////////////////

resource "azurerm_storage_account" "bosh_root_storage_account" {
  name                     = "${var.env_short_name}root"
  resource_group_name      = "${azurerm_resource_group.pcf_resource_group.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "ops_manager_storage_account" {
  name                     = "${var.env_short_name}infra"
  resource_group_name      = "${azurerm_resource_group.pcf_resource_group.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "ops_manager_storage_container" {
  name                  = "opsmanagerimage"
  depends_on            = ["azurerm_storage_account.ops_manager_storage_account"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.ops_manager_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_blob" "ops_manager_image" {
  name                   = "opsman.vhd"
  resource_group_name    = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name   = "${azurerm_storage_account.ops_manager_storage_account.name}"
  storage_container_name = "${azurerm_storage_container.ops_manager_storage_container.name}"
  source_uri             = "${var.ops_manager_image_uri}"
}

resource "azurerm_storage_container" "bosh_storage_container" {
  name                  = "bosh"
  depends_on            = ["azurerm_storage_account.bosh_root_storage_account"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.bosh_root_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "stemcell_storage_container" {
  name                  = "stemcell"
  depends_on            = ["azurerm_storage_account.bosh_root_storage_account"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.bosh_root_storage_account.name}"
  container_access_type = "blob"
}

resource "azurerm_storage_table" "stemcells_storage_table" {
  name                 = "stemcells"
  resource_group_name  = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name = "${azurerm_storage_account.bosh_root_storage_account.name}"
}

resource "azurerm_storage_account" "bosh_vms_storage_account_1" {
  name                     = "${var.env_short_name}${data.template_file.base_storage_account_wildcard.rendered}1"
  resource_group_name      = "${azurerm_resource_group.pcf_resource_group.name}"
  location                 = "${var.location}"
  account_tier             = "Premium"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "bosh_storage_container_1" {
  name                  = "bosh"
  depends_on            = ["azurerm_storage_account.bosh_vms_storage_account_1"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.bosh_vms_storage_account_1.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "stemcell_storage_container_1" {
  name                  = "stemcell"
  depends_on            = ["azurerm_storage_account.bosh_vms_storage_account_1"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.bosh_vms_storage_account_1.name}"
  container_access_type = "private"
}

resource "azurerm_storage_account" "bosh_vms_storage_account_2" {
  name                     = "${var.env_short_name}${data.template_file.base_storage_account_wildcard.rendered}2"
  resource_group_name      = "${azurerm_resource_group.pcf_resource_group.name}"
  location                 = "${var.location}"
  account_tier             = "Premium"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "bosh_storage_container_2" {
  name                  = "bosh"
  depends_on            = ["azurerm_storage_account.bosh_vms_storage_account_2"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.bosh_vms_storage_account_2.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "stemcell_storage_container_2" {
  name                  = "stemcell"
  depends_on            = ["azurerm_storage_account.bosh_vms_storage_account_2"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.bosh_vms_storage_account_2.name}"
  container_access_type = "private"
}

resource "azurerm_storage_account" "bosh_vms_storage_account_3" {
  name                     = "${var.env_short_name}${data.template_file.base_storage_account_wildcard.rendered}3"
  resource_group_name      = "${azurerm_resource_group.pcf_resource_group.name}"
  location                 = "${var.location}"
  account_tier             = "Premium"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "bosh_storage_container_3" {
  name                  = "bosh"
  depends_on            = ["azurerm_storage_account.bosh_vms_storage_account_3"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.bosh_vms_storage_account_3.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "stemcell_storage_container_3" {
  name                  = "stemcell"
  depends_on            = ["azurerm_storage_account.bosh_vms_storage_account_3"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.bosh_vms_storage_account_3.name}"
  container_access_type = "private"
}

resource "azurerm_storage_account" "ert_storage_account" {
  name                     = "${var.env_short_name}${var.azure_account_name}"
  resource_group_name      = "${azurerm_resource_group.pcf_resource_group.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    job = "ert_storage_account"
  }
}

resource "azurerm_storage_container" "ert_storage_container_buildpacks" {
  name                  = "${var.azure_buildpacks_container}"
  depends_on            = ["azurerm_storage_account.ert_storage_account"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.ert_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "ert_storage_container_droplets" {
  name                  = "${var.azure_droplets_container}"
  depends_on            = ["azurerm_storage_account.ert_storage_account"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.ert_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "ert_storage_container_packages" {
  name                  = "${var.azure_packages_container}"
  depends_on            = ["azurerm_storage_account.ert_storage_account"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.ert_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "ert_storage_container_resources" {
  name                  = "${var.azure_resources_container}"
  depends_on            = ["azurerm_storage_account.ert_storage_account"]
  resource_group_name   = "${azurerm_resource_group.pcf_resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.ert_storage_account.name}"
  container_access_type = "private"
}
