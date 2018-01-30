///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
//////// Set Ops Mgr //////////////////////////
///////////////////////////////////////////////

resource "azurerm_network_interface" "ops_manager_nic" {
  name                = "${var.env_name}-ops-manager-nic"
  location            = "${var.location}"
  resource_group_name = "${var.azure_multi_resgroup_pcf}"

  ip_configuration {
    name                          = "${var.env_name}-ops-manager-ip-config"
    subnet_id                     = "${var.subnet_infra_id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${var.azure_opsman_priv_ip}"
    public_ip_address_id          = "${var.pub_ip_id_opsman_vm}"
  }
}

resource "azurerm_virtual_machine" "ops_manager_vm" {
  name                  = "${var.env_name}-ops-manager-vm"
  depends_on            = ["azurerm_network_interface.ops_manager_nic", "azurerm_storage_blob.ops_manager_image"]
  location              = "${var.location}"
  resource_group_name   = "${var.azure_multi_resgroup_pcf}"
  network_interface_ids = ["${azurerm_network_interface.ops_manager_nic.id}"]
  vm_size               = "Standard_DS2_v2"

  storage_os_disk {
    name          = "opsman-disk.vhd"
    vhd_uri       = "${azurerm_storage_account.ops_manager_storage_account.primary_blob_endpoint}${azurerm_storage_container.ops_manager_storage_container.name}/opsman-disk.vhd"
    image_uri     = "${azurerm_storage_blob.ops_manager_image.url}"
    caching       = "ReadWrite"
    os_type       = "linux"
    create_option = "FromImage"
    disk_size_gb  = "${var.om_disk_size_in_gb}"
  }

  os_profile {
    computer_name  = "${var.env_name}-ops-manager"
    admin_username = "${var.vm_admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.vm_admin_username}/.ssh/authorized_keys"
      key_data = "${var.vm_admin_public_key}"
    }
  }
}
