variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "aws_key_name" {}
variable "aws_cert_arn" {}
variable "db_master_username" {}
variable "db_master_password" {}
variable "prefix" {}
variable "opsman_ami" {}
variable "amis_nat" {}
variable "aws_region" {}
variable "route53_zone_id" {}

/*
* used for configuring ingress rules to ops manager vm
*/
variable "opsman_allow_ssh" {
  default = false
}

variable "opsman_allow_https" {
  default = false
}

variable "opsman_allow_ssh_cidr_ranges" {
  type    = "list"
  default = ["0.0.0.0/32"]
}

variable "opsman_allow_https_cidr_ranges" {
  type    = "list"
  default = ["0.0.0.0/32"]
}

variable "opsman_instance_type" {
  description = "Instance Type for OpsMan"
  default     = "m3.large"
}

variable "db_instance_type" {
  description = "Instance Type for RDS instance"
  default     = "db.m3.large"
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default     = "10.0.0.0/16"
}

variable "apps_domain" {}
variable "system_domain" {}
