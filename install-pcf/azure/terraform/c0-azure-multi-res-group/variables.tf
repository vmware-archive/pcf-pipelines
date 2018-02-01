///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
//////// Set Azure Variables //////////////////
///////////////////////////////////////////////

variable "azure_opsman_priv_ip" {}

variable "env_name" {}

variable "env_short_name" {
  description = "Used for creating storage accounts. Must be a-z only, no longer than 10 characters"
}

variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "location" {}

variable "pcf_ert_domain" {}
variable "apps_domain" {}
variable "system_domain" {}

variable "pub_ip_pcf_lb" {}
variable "pub_ip_id_pcf_lb" {}

variable "pub_ip_tcp_lb" {}
variable "pub_ip_id_tcp_lb" {}

variable "pub_ip_ssh_proxy_lb" {}
variable "pub_ip_id_ssh_proxy_lb" {}

variable "priv_ip_mysql_lb" {}

variable "pub_ip_jumpbox_vm" {}
variable "pub_ip_id_jumpbox_vm" {}

variable "pub_ip_opsman_vm" {}
variable "pub_ip_id_opsman_vm" {}

variable "subnet_infra_id" {}

variable "ops_manager_image_uri" {}
variable "vm_admin_username" {}
variable "vm_admin_public_key" {}

variable "ert_subnet_id" {}
variable "azure_multi_resgroup_network" {}
variable "azure_multi_resgroup_pcf" {}
variable "om_disk_size_in_gb" {}
