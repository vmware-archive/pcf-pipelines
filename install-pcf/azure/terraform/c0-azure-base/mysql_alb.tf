///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
//////// ALB for MySQL ////////////////////////
///////////////////////////////////////////////

resource "azurerm_lb" "mysql" {
  name                = "${var.env_name}-mysql-lb"
  depends_on          = ["azurerm_subnet.ert_subnet"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"

  frontend_ip_configuration = {
    name      = "frontendip"
    subnet_id = "${azurerm_subnet.ert_subnet.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "mysql-backend-pool" {
  name                = "mysql-backend-pool"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  loadbalancer_id     = "${azurerm_lb.mysql.id}"
}

resource "azurerm_lb_probe" "mysql-probe" {
  name                = "mysql-probe"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  loadbalancer_id     = "${azurerm_lb.mysql.id}"
  protocol            = "TCP"
  port                = 1936
}

resource "azurerm_lb_rule" "mysql-rule" {
  name                = "mysql-rule"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.pcf_resource_group.name}"
  loadbalancer_id     = "${azurerm_lb.mysql.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 3306
  backend_port                   = 3306

  # Workaround until the backend_address_pool and probe resources output their own ids
  backend_address_pool_id = "${azurerm_lb.mysql.id}/backendAddressPools/${azurerm_lb_backend_address_pool.mysql-backend-pool.name}"
  probe_id                = "${azurerm_lb.mysql.id}/probes/${azurerm_lb_probe.mysql-probe.name}"
}
