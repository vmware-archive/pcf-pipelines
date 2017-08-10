///////////////////////////////////////////////
//////// Pivotal Customer[0]       ////////////
////////              ALB          ////////////
///////////////////////////////////////////////

////////////////////////////////
//// Azure Load Balancer Configs
////////////////////////////////

// API&APPS ALB
resource "azurerm_lb" "web" {
  name                = "${var.env_name}-web-lb"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"

  frontend_ip_configuration = {
    name                 = "frontendip"
    public_ip_address_id = "${var.pub_ip_id_pcf_lb}"
  }
}

// TCP ALB
resource "azurerm_lb" "tcp" {
  name                = "${var.env_name}-tcp-lb"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"

  frontend_ip_configuration = {
    name                 = "frontendip"
    public_ip_address_id = "${var.pub_ip_id_tcp_lb}"
  }
}


// SSH-Proxy ALB
resource "azurerm_lb" "ssh-proxy" {
  name                = "${var.env_name}-ssh-proxy-lb"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"

  frontend_ip_configuration = {
    name                 = "frontendip"
    public_ip_address_id = "${var.pub_ip_id_ssh_proxy_lb}"
  }
}

////////////////////////////////
//// Backend Pools
////////////////////////////////

// API&APPS
resource "azurerm_lb_backend_address_pool" "web-backend-pool" {
  name                = "web-backend-pool"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.web.id}"
}

// TCP Load Balancer
resource "azurerm_lb_backend_address_pool" "tcp-backend-pool" {
  name                = "tcp-backend-pool"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.tcp.id}"
}

// SSH Proxy
resource "azurerm_lb_backend_address_pool" "ssh-backend-pool" {
  name                = "ssh-backend-pool"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.ssh-proxy.id}"
}

////////////////////////////////
//// Health Checks
////////////////////////////////

// Go Router HTTPS
resource "azurerm_lb_probe" "web-https-probe" {
  name                = "web-https-probe"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.web.id}"
  protocol            = "TCP"
  port                = 443
}


// Go Router HTTP
resource "azurerm_lb_probe" "web-http-probe" {
  name                = "web-http-probe"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.web.id}"
  protocol            = "TCP"
  port                = 80
}


// TCP LB 80
resource "azurerm_lb_probe" "tcp-probe" {
  name                = "tcp-probe"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.tcp.id}"
  protocol            = "TCP"
  port                = 80
}

// Diego Brain 2222
resource "azurerm_lb_probe" "ssh-proxy-probe" {
  name                = "ssh-proxy-probe"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.ssh-proxy.id}"
  protocol            = "TCP"
  port                = 2222
}

////////////////////////////////
//// Load Balancing Rules
////////////////////////////////


// API&APPS HTTPS
resource "azurerm_lb_rule" "web-https-rule" {
  name                = "web-https-rule"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.web.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 443
  backend_port                   = 443

  # Workaround until the backend_address_pool and probe resources output their own ids
  backend_address_pool_id = "${azurerm_lb.web.id}/backendAddressPools/${azurerm_lb_backend_address_pool.web-backend-pool.name}"
  probe_id                = "${azurerm_lb.web.id}/probes/${azurerm_lb_probe.web-https-probe.name}"
}

// API&APPS HTTP
resource "azurerm_lb_rule" "web-http-rule" {
  name                = "web-http-rule"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.web.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 80
  backend_port                   = 80

  # Workaround until the backend_address_pool and probe resources output their own ids
  backend_address_pool_id = "${azurerm_lb.web.id}/backendAddressPools/${azurerm_lb_backend_address_pool.web-backend-pool.name}"
  probe_id                = "${azurerm_lb.web.id}/probes/${azurerm_lb_probe.web-http-probe.name}"
}


// TCP LB
resource "azurerm_lb_rule" "tcp-rule" {
  count               = 150
  name                = "tcp-rule-${count.index + 1024}"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.tcp.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = "${count.index + 1024}"
  backend_port                   = "${count.index + 1024}"

  # Workaround until the backend_address_pool and probe resources output their own ids
  backend_address_pool_id = "${azurerm_lb.tcp.id}/backendAddressPools/${azurerm_lb_backend_address_pool.tcp-backend-pool.name}"
  probe_id                = "${azurerm_lb.tcp.id}/probes/${azurerm_lb_probe.tcp-probe.name}"
}

// SSH Proxy
resource "azurerm_lb_rule" "ssh-proxy-rule" {
  name                = "ssh-proxy-rule"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"
  loadbalancer_id     = "${azurerm_lb.ssh-proxy.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 2222
  backend_port                   = 2222

  # Workaround until the backend_address_pool and probe resources output their own ids
  backend_address_pool_id = "${azurerm_lb.ssh-proxy.id}/backendAddressPools/${azurerm_lb_backend_address_pool.ssh-backend-pool.name}"
  probe_id                = "${azurerm_lb.ssh-proxy.id}/probes/${azurerm_lb_probe.ssh-proxy-probe.name}"
}
