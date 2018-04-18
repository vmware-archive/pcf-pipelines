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

variable "azure_terraform_vnet_cidr" {}
variable "azure_terraform_subnet_infra_cidr" {}
variable "azure_terraform_subnet_ert_cidr" {}
variable "azure_terraform_subnet_services1_cidr" {}
variable "azure_terraform_subnet_dynamic_services_cidr" {}

variable "pcf_ert_domain" {}
variable "apps_domain" {}
variable "system_domain" {}

variable "ops_manager_image_uri" {}
variable "vm_admin_username" {}
variable "vm_admin_public_key" {}

variable "azure_storage_account_name" {}
variable "azure_buildpacks_container" {}
variable "azure_droplets_container" {}
variable "azure_packages_container" {}
variable "azure_resources_container" {}
variable "om_disk_size_in_gb" {}
variable "azure_opsman_priv_ip" {}
