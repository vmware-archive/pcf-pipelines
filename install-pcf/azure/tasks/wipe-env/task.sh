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

function delete-opsman() {
  az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
  local opsman_vms=$(az vm list -g $AZURE_TERRAFORM_PREFIX | jq -r ".[].name | select(. |startswith(\"$AZURE_TERRAFORM_PREFIX-ops-manager\"))")

  for om_vm_name in $opsman_vms; do
    echo "Removing $om_vm_name ..."
    az vm delete --yes --resource-group $AZURE_TERRAFORM_PREFIX --name "$om_vm_name"
  done
}

function delete-infrastructure() {
  echo "=============================================================================================="
  echo "Executing Terraform Destroy ...."
  echo "=============================================================================================="

  terraform init "pcf-pipelines/install-pcf/azure/terraform/${AZURE_PCF_TERRAFORM_TEMPLATE}"

  terraform destroy -force \
    -var "subscription_id=${AZURE_SUBSCRIPTION_ID}" \
    -var "client_id=${AZURE_CLIENT_ID}" \
    -var "client_secret=${AZURE_CLIENT_SECRET}" \
    -var "tenant_id=${AZURE_TENANT_ID}" \
    -var "location=dontcare" \
    -var "env_name=dontcare" \
    -var "env_short_name=dontcare" \
    -var "azure_terraform_vnet_cidr=dontcare" \
    -var "azure_terraform_subnet_infra_cidr=dontcare" \
    -var "azure_terraform_subnet_ert_cidr=dontcare" \
    -var "azure_terraform_subnet_services1_cidr=dontcare" \
    -var "azure_terraform_subnet_dynamic_services_cidr=dontcare" \
    -var "ert_subnet_id=dontcare" \
    -var "pcf_ert_domain=dontcare" \
    -var "system_domain=dontcare" \
    -var "apps_domain=dontcare" \
    -var "pub_ip_pcf_lb=dontcare" \
    -var "pub_ip_id_pcf_lb=dontcare" \
    -var "pub_ip_tcp_lb=dontcare" \
    -var "pub_ip_id_tcp_lb=dontcare" \
    -var "priv_ip_mysql_lb=dontcare" \
    -var "pub_ip_ssh_proxy_lb=dontcare" \
    -var "pub_ip_id_ssh_proxy_lb=dontcare" \
    -var "pub_ip_opsman_vm=dontcare" \
    -var "pub_ip_id_opsman_vm=dontcare" \
    -var "pub_ip_jumpbox_vm=dontcare" \
    -var "pub_ip_id_jumpbox_vm=dontcare" \
    -var "subnet_infra_id=dontcare" \
    -var "ops_manager_image_uri=dontcare" \
    -var "vm_admin_username=dontcare" \
    -var "vm_admin_public_key=dontcare" \
    -var "azure_multi_resgroup_network=dontcare" \
    -var "azure_multi_resgroup_pcf=dontcare" \
    -var "azure_opsman_priv_ip=dontcare" \
    -var "azure_account_name=dontcare" \
    -var "azure_buildpacks_container=dontcare" \
    -var "azure_droplets_container=dontcare" \
    -var "azure_packages_container=dontcare" \
    -var "azure_resources_container=dontcare" \
    -var "om_disk_size_in_gb=50" \
    -state "${ROOT}/terraform-state/terraform.tfstate" \
    -state-out "${ROOT}/terraform-state-output/terraform.tfstate" \
    "pcf-pipelines/install-pcf/azure/terraform/${AZURE_PCF_TERRAFORM_TEMPLATE}"
}

function main() {
  if [[ "${ARG_WIPE}" == "wipe" ]]; then
    echo "Wiping Environment...."
  else
    echo "Need Args [0]=wipe, anything else and I swear I'll exit and do nothing!!! "
    echo "Example: ./wipe-env.sh wipe ..."
    exit 0
  fi

  delete-opsman-installation
  delete-opsman
  delete-infrastructure
}

main
