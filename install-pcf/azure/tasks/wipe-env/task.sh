#!/bin/bash
set -eu

ROOT="${PWD}"

function delete-opsman-installation() {
  source "${ROOT}/pcf-pipelines/functions/check_opsman_available.sh"

  OPSMAN_AVAILABLE=$(check_opsman_available "${OPSMAN_DOMAIN_OR_IP_ADDRESS}")
  if [[ ${OPSMAN_AVAILABLE} == "available" ]]; then
    om-linux \
      --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
      --skip-ssl-validation \
      --username "${OPSMAN_USERNAME}" \
      --password "${OPSMAN_PASSWORD}" \
      delete-installation
  fi
}

function delete-infrastructure() {
  echo "=============================================================================================="
  echo "Executing Terraform Destroy ...."
  echo "=============================================================================================="

  terraform init "/home/vcap/app/terraforming-azure"

  terraform destroy -force \
    -var-file "${ROOT}/terraform-vars/terraform.tfvars" \
    -state "${ROOT}/terraform-state/terraform.tfstate" \
    -state-out "${ROOT}/terraform-state-output/terraform.tfstate" \
    "/home/vcap/app/terraforming-azure"
}

function main() {
  delete-opsman-installation
  delete-infrastructure
}

main
