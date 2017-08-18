#!/bin/bash
set -eu

ROOT="${PWD}"

function delete-opsman() {
  source "${ROOT}/pcf-pipelines/functions/check_opsman_available.sh"

  opsman_available=$(check_opsman_available "${OPSMAN_DOMAIN_OR_IP_ADDRESS}")
  if [[ ${opsman_available} == "available" ]]; then
    om-linux \
      --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
      --skip-ssl-validation \
      --username ${OPSMAN_USERNAME} \
      --password ${OPSMAN_PASSWORD} \
      delete-installation
  fi
}

function delete-infrastructure() {
  echo "=============================================================================================="
  echo "Executing Terraform Destroy ...."
  echo "=============================================================================================="

  terraform destroy -force \
    -var "subscription_id=${azure_subscription_id}" \
    -var "client_id=${azure_service_principal_id}" \
    -var "client_secret=${azure_service_principal_password}" \
    -var "tenant_id=${azure_tenant_id}" \
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
    -var "vm_admin_password=dontcare" \
    -var "vm_admin_public_key=dontcare" \
    -var "azure_multi_resgroup_network=dontcare" \
    -var "azure_multi_resgroup_pcf=dontcare" \
    -var "priv_ip_opsman_vm=dontcare" \
    -var "azure_account_name=dontcare" \
    -var "azure_buildpacks_container=dontcare" \
    -var "azure_droplets_container=dontcare" \
    -var "azure_packages_container=dontcare" \
    -var "azure_resources_container=dontcare" \
    -state "${ROOT}/terraform-state/terraform.tfstate" \
    -state-out "${ROOT}/terraform-state-output/terraform.tfstate" \
    "pcf-pipelines/install-pcf/azure/terraform/${azure_pcf_terraform_template}"
}

function main() {
  if [[ "${arg_wipe}" == "wipe" ]]; then
    echo "Wiping Environment...."
  else
    echo "Need Args [0]=wipe, anything else and I swear I'll exit and do nothing!!! "
    echo "Example: ./wipe-env.sh wipe ..."
    exit 0
  fi

  delete-opsman
  delete-infrastructure
}

main
