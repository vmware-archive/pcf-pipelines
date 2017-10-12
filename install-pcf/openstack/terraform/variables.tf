variable "os_tenant_name" {}
variable "os_username" {}
variable "os_password" {}
variable "os_auth_url" {}
variable "os_region" {}
variable "os_domain_name" {}

variable "prefix" {}

variable "infra_subnet_cidr" {}
variable "ert_subnet_cidr" {}
variable "services_subnet_cidr" {}
variable "dynamic_services_subnet_cidr" {}

variable "infra_dns" {}
variable "ert_dns" {}
variable "services_dns" {}
variable "dynamic_services_dns" {}

variable "external_network" {}
// TODO: Can we query external network id from name?
variable "external_network_id" {}

variable "opsman_image_name" {}
variable "opsman_public_key" {}
variable "opsman_volume_size" {}
variable "opsman_flavor" {}
variable "opsman_fixed_ip" {}
