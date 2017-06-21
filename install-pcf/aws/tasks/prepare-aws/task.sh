#!/bin/bash

set -ex

ami=$(cat ami/ami)

OPSMAN_ALLOW_SSH=0
OPSMAN_ALLOW_SSH_CIDR_LIST='["0.0.0.0/32"]'
if [[ -n "${OPSMAN_ALLOW_SSH_CIDR_RANGES// }" ]]; then
  OPSMAN_ALLOW_SSH=1
  OPSMAN_ALLOW_SSH_CIDR_LIST='["'${OPSMAN_ALLOW_SSH_CIDR_RANGES/\,/\"\,\"}'"]'
fi

OPSMAN_ALLOW_HTTPS=0
OPSMAN_ALLOW_HTTPS_CIDR_LIST='["0.0.0.0/32"]'
if [[ -n "${OPSMAN_ALLOW_HTTPS_CIDR_RANGES// }" ]]; then
  OPSMAN_ALLOW_HTTPS=1
  OPSMAN_ALLOW_HTTPS_CIDR_LIST='["'${OPSMAN_ALLOW_HTTPS_CIDR_RANGES/\,/\"\,\"}'"]'
fi

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
  -out terraform.tfplan \
  pcf-pipelines/install-pcf/aws/terraform

terraform apply \
  -state-out terraform-state-output/terraform.tfstate \
  terraform.tfplan
