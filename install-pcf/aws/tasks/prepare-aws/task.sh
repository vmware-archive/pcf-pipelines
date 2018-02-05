#!/bin/bash

set -eu

ami=$(cat ami/ami)

OPSMAN_ALLOW_SSH=0
OPSMAN_ALLOW_SSH_CIDR_LIST='["0.0.0.0/32"]'
if [[ -n "${OPSMAN_ALLOW_SSH_CIDR_RANGES// }" ]]; then
  OPSMAN_ALLOW_SSH=1
  OPSMAN_ALLOW_SSH_CIDR_LIST='["'${OPSMAN_ALLOW_SSH_CIDR_RANGES//\,/\"\,\"}'"]'
fi

OPSMAN_ALLOW_HTTPS=0
OPSMAN_ALLOW_HTTPS_CIDR_LIST='["0.0.0.0/32"]'
if [[ -n "${OPSMAN_ALLOW_HTTPS_CIDR_RANGES// }" ]]; then
  OPSMAN_ALLOW_HTTPS=1
  OPSMAN_ALLOW_HTTPS_CIDR_LIST='["'${OPSMAN_ALLOW_HTTPS_CIDR_RANGES//\,/\"\,\"}'"]'
fi

terraform init pcf-pipelines/install-pcf/aws/terraform

terraform plan \
  -state terraform-state/terraform.tfstate \
  -var "opsman_ami=${ami}" \
  -var "db_master_username=${DB_MASTER_USERNAME}" \
  -var "db_master_password=${DB_MASTER_PASSWORD}" \
  -var "prefix=${TERRAFORM_PREFIX}" \
  -var "opsman_allow_ssh=${OPSMAN_ALLOW_SSH}" \
  -var "opsman_allow_ssh_cidr_ranges=${OPSMAN_ALLOW_SSH_CIDR_LIST}" \
  -var "opsman_allow_https=${OPSMAN_ALLOW_HTTPS}" \
  -var "opsman_allow_https_cidr_ranges=${OPSMAN_ALLOW_HTTPS_CIDR_LIST}" \
  -var "aws_access_key_id=${aws_access_key_id}" \
  -var "aws_secret_access_key=${aws_secret_access_key}" \
  -var "aws_key_name=${aws_key_name}" \
  -var "aws_cert_arn=${aws_cert_arn}" \
  -var "amis_nat=${amis_nat}" \
  -var "aws_region=${aws_region}" \
  -var "aws_az1=${aws_az1}" \
  -var "aws_az2=${aws_az2}" \
  -var "aws_az3=${aws_az3}" \
  -var "route53_zone_id=${route53_zone_id}" \
  -var "vpc_cidr=${vpc_cidr}" \
  -var "system_domain=${system_domain}" \
  -var "apps_domain=${apps_domain}" \
  -var "public_subnet_cidr_az1=${public_subnet_cidr_az1}" \
  -var "public_subnet_cidr_az2=${public_subnet_cidr_az2}" \
  -var "public_subnet_cidr_az3=${public_subnet_cidr_az3}" \
  -var "ert_subnet_cidr_az1=${ert_subnet_cidr_az1}" \
  -var "ert_subnet_cidr_az2=${ert_subnet_cidr_az2}" \
  -var "ert_subnet_cidr_az3=${ert_subnet_cidr_az3}" \
  -var "services_subnet_cidr_az1=${services_subnet_cidr_az1}" \
  -var "services_subnet_cidr_az2=${services_subnet_cidr_az2}" \
  -var "services_subnet_cidr_az3=${services_subnet_cidr_az3}" \
  -var "dynamic_services_subnet_cidr_az1=${dynamic_services_subnet_cidr_az1}" \
  -var "dynamic_services_subnet_cidr_az2=${dynamic_services_subnet_cidr_az2}" \
  -var "dynamic_services_subnet_cidr_az3=${dynamic_services_subnet_cidr_az3}" \
  -var "infra_subnet_cidr_az1=${infra_subnet_cidr_az1}" \
  -var "rds_subnet_cidr_az1=${rds_subnet_cidr_az1}" \
  -var "rds_subnet_cidr_az2=${rds_subnet_cidr_az2}" \
  -var "rds_subnet_cidr_az3=${rds_subnet_cidr_az3}" \
  -var "opsman_ip_az1=${opsman_ip_az1}" \
  -var "nat_ip_az1=${nat_ip_az1}" \
  -var "nat_ip_az2=${nat_ip_az2}" \
  -var "nat_ip_az3=${nat_ip_az3}" \
  -out terraform.tfplan \
  pcf-pipelines/install-pcf/aws/terraform

terraform apply \
  -state-out terraform-state-output/terraform.tfstate \
  terraform.tfplan
