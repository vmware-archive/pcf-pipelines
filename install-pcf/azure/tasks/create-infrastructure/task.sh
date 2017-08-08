#!/bin/bash
set -e

# Copy base template with no clobber if not using the base template
if [[ ! ${azure_pcf_terraform_template} == "c0-azure-base" ]]; then
  cp -rn pcf-pipelines/install-pcf/azure/terraform/c0-azure-base/* pcf-pipelines/install-pcf/azure/terraform/${azure_pcf_terraform_template}/
fi

# Get ert subnet if multi-resgroup
az login --service-principal -u ${azure_service_principal_id} -p ${azure_service_principal_password} --tenant ${azure_tenant_id}
az account set --subscription ${azure_subscription_id}
ert_subnet_cmd="az network vnet subnet list -g network-core --vnet-name vnet-pcf --output json | jq '.[] | select(.name == \"ert\") | .id' | tr -d '\"'"
ert_subnet=$(eval $ert_subnet_cmd)
echo "Found SubnetID=${ert_subnet}"

echo "=============================================================================================="
echo "Collecting Terraform Variables from Deployed Azure Objects ...."
echo "=============================================================================================="

# Get Opsman VHD from previous task
pcf_opsman_image_uri=$(cat opsman-metadata/uri)

# Use prefix to strip down a Storage Account Prefix String
env_short_name=$(echo ${azure_terraform_prefix} | tr -d "-" | tr -d "_" | tr -d "[0-9]")
env_short_name=$(echo ${env_short_name:0:10})

##########################################################
# Detect generate for ssh keys
##########################################################

if [[ ${pcf_ssh_key_pub} == 'generate' ]]; then
  echo "Generating SSH keys for Opsman"
  ssh-keygen -t rsa -f opsman -C ubuntu -q -P ""
  pcf_ssh_key_pub=$(cat opsman.pub)
  pcf_ssh_key_priv=$(cat opsman)
  echo "******************************"
  echo "******************************"
  echo "pcf_ssh_key_pub = ${pcf_ssh_key_pub}"
  echo "******************************"
  echo "pcf_ssh_key_priv = ${pcf_ssh_key_priv}"
  echo "******************************"
  echo "******************************"
fi

echo "=============================================================================================="
echo "Executing Terraform Plan ..."
echo "=============================================================================================="

terraform plan \
  -var "subscription_id=${azure_subscription_id}" \
  -var "client_id=${azure_service_principal_id}" \
  -var "client_secret=${azure_service_principal_password}" \
  -var "tenant_id=${azure_tenant_id}" \
  -var "location=${azure_region}" \
  -var "env_name=${azure_terraform_prefix}" \
  -var "env_short_name=${env_short_name}" \
  -var "azure_terraform_vnet_cidr=${azure_terraform_vnet_cidr}" \
  -var "azure_terraform_subnet_infra_cidr=${azure_terraform_subnet_infra_cidr}" \
  -var "azure_terraform_subnet_ert_cidr=${azure_terraform_subnet_ert_cidr}" \
  -var "azure_terraform_subnet_services1_cidr=${azure_terraform_subnet_services1_cidr}" \
  -var "azure_terraform_subnet_dynamic_services_cidr=${azure_terraform_subnet_dynamic_services_cidr}" \
  -var "ert_subnet_id=${ert_subnet}" \
  -var "pcf_ert_domain=${pcf_ert_domain}" \
  -var "ops_manager_image_uri=${pcf_opsman_image_uri}" \
  -var "vm_admin_username=${azure_vm_admin}" \
  -var "vm_admin_password=${azure_vm_password}" \
  -var "vm_admin_public_key=${pcf_ssh_key_pub}" \
  -var "azure_multi_resgroup_network=${e_multi_resgroup_network}" \
  -var "azure_multi_resgroup_pcf=${azure_multi_resgroup_pcf}" \
  -var "priv_ip_opsman_vm=${azure_terraform_opsman_priv_ip}" \
  -var "azure_account_name=${azure_account_name}" \
  -var "azure_buildpacks_container=${azure_buildpacks_container}" \
  -var "azure_droplets_container=${azure_droplets_container}" \
  -var "azure_packages_container=${azure_packages_container}" \
  -var "azure_resources_container=${azure_resources_container}" \
  -out terraform.tfplan \
  -state terraform-state/terraform.tfstate \
  pcf-pipelines/install-pcf/azure/terraform/$azure_pcf_terraform_template

echo "=============================================================================================="
echo "Executing Terraform Apply ..."
echo "=============================================================================================="

terraform apply \
  -state-out terraform-state-output/terraform.tfstate \
  terraform.tfplan
