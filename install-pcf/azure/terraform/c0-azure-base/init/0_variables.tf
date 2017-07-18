///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
//////// Set Azure Variables //////////////////
///////////////////////////////////////////////

variable "env_name" {}
variable "subscription_id" {}
variable "tenant_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "location" {}

variable "azure_terraform_vnet_cidr" {}
variable "azure_terraform_subnet_infra_cidr" {}
variable "azure_terraform_subnet_ert_cidr" {}
variable "azure_terraform_subnet_services1_cidr" {}
variable "azure_terraform_subnet_dynamic_services_cidr" {}
