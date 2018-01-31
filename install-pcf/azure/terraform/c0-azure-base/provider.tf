///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
//////// Set Azure Provider info///////////////
///////////////////////////////////////////////

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"

  version         = "1.0.0"
}
