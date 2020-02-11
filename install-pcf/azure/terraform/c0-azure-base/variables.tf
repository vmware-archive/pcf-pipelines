///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
//////// Set Azure Variables //////////////////
///////////////////////////////////////////////

variable "env_name" {}

variable "env_short_name" {
  description = "Used for creating storage accounts. Must be a-z only, no longer than 10 characters"
}

variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "location" {}

variable "azure_terraform_vnet_cidr" {
  default = "192.168.0.0/20"
}
variable "azure_terraform_subnet_infra_cidr" {
  default = "192.168.0.0/26"
}
variable "azure_terraform_subnet_ert_cidr" {
  default = "192.168.4.0/22"
}
variable "azure_terraform_subnet_services1_cidr" {
  default = "192.168.8.0/22"
}
variable "azure_terraform_subnet_dynamic_services_cidr" {
  default = "192.168.12.0/22"
}

variable "ert_subnet_id" {
  default = ""
}

variable "pcf_ert_domain" {}
variable "apps_domain" {}
variable "system_domain" {}

variable "ops_manager_image_uri" {}
variable "vm_admin_username" {}
variable "vm_admin_public_key" {}
variable "azure_multi_resgroup_network" {
  default = ""
}
variable "azure_multi_resgroup_pcf" {
  default = ""
}

variable "azure_ert_storage_account_name" {}
variable "azure_buildpacks_container" {
  default = "buildpacks"
}
variable "azure_droplets_container" {
  default = "droplets"
}
variable "azure_packages_container" {
  default = "packages"
}
variable "azure_resources_container" {
  default = "resources"
}
variable "om_disk_size_in_gb" {
  default = "120"
}
variable "azure_opsman_priv_ip" {
  default = "192.168.0.4"
}
variable "azure_lb_sku" {
  default = "Standard"
}
variable "terraform_azure_storage_access_key" {}
variable "terraform_azure_storage_account_name" {}
variable "terraform_azure_storage_container_name" {
  default = "terraformstate"
}
