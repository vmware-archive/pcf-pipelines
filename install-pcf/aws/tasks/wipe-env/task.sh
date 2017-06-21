#!/bin/bash
set -e

root=$(pwd)

cd pcf-pipelines/install-pcf/aws/terraform

source "${root}/pcf-pipelines/functions/check_opsman_available.sh"

opsman_available=$(check_opsman_available $OPSMAN_URI)
if [[ $opsman_available == "available" ]]; then
  om-linux \
    --target "https://${OPSMAN_URI}" \
    --skip-ssl-validation \
    --username $OPSMAN_USERNAME \
    --password $OPSMAN_PASSWORD \
    delete-installation
fi

export AWS_ACCESS_KEY_ID=${TF_VAR_aws_access_key}
export AWS_SECRET_ACCESS_KEY=${TF_VAR_aws_secret_key}
export AWS_DEFAULT_REGION=${TF_VAR_aws_region}

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

terraform destroy \
  -force \
  -var "opsman_ami=dontcare" \
  -var "db_master_username=dontcare" \
  -var "db_master_password=dontcare" \
  -var "prefix=dontcare" \
  -var "opsman_allow_ssh=${OPSMAN_ALLOW_SSH}" \
  -var "opsman_allow_ssh_cidr_ranges=${OPSMAN_ALLOW_SSH_CIDR_LIST}" \
  -var "opsman_allow_https=${OPSMAN_ALLOW_HTTPS}" \
  -var "opsman_allow_https_cidr_ranges=${OPSMAN_ALLOW_HTTPS_CIDR_LIST}" \
  -state "${root}/terraform-state/terraform.tfstate" \
  -state-out "${root}/terraform-state-output/terraform.tfstate"
