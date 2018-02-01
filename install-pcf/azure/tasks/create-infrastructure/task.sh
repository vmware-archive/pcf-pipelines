#!/bin/bash
set -e

# Copy base template with no clobber if not using the base template
if [[ ! ${AZURE_PCF_TERRAFORM_TEMPLATE} == "c0-azure-base" ]]; then
  cp -rn pcf-pipelines/install-pcf/azure/terraform/c0-azure-base/* pcf-pipelines/install-pcf/azure/terraform/${AZURE_PCF_TERRAFORM_TEMPLATE}/
fi

# Get ert subnet if multi-resgroup
az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}
az account set --subscription ${AZURE_SUBSCRIPTION_ID}
ERT_SUBNET_CMD="az network vnet subnet list -g network-core --vnet-name vnet-pcf --output json | jq '.[] | select(.name == \"ert\") | .id' | tr -d '\"'"
ERT_SUBNET=$(eval ${ERT_SUBNET_CMD})
echo "Found SubnetID=${ERT_SUBNET}"

echo "=============================================================================================="
echo "Collecting Terraform Variables from Deployed Azure Objects ...."
echo "=============================================================================================="

# Get Opsman VHD from previous task
PCF_OPSMAN_IMAGE_URI=$(cat opsman-metadata/uri)

# Use prefix to strip down a Storage Account Prefix String
ENV_SHORT_NAME=$(echo ${AZURE_TERRAFORM_PREFIX} | tr -d "-" | tr -d "_" | tr -d "[0-9]")
ENV_SHORT_NAME=$(echo ${ENV_SHORT_NAME:0:10})

##########################################################
# Detect generate for ssh keys
##########################################################

if [[ ${PCF_SSH_KEY_PUB} == 'generate' ]]; then
  echo "Generating SSH keys for Opsman"
  ssh-keygen -t rsa -f opsman -C ubuntu -q -P ""
  PCF_SSH_KEY_PUB="$(cat opsman.pub)"
  PCF_SSH_KEY_PRIV="$(cat opsman)"
  echo "******************************"
  echo "******************************"
  echo "pcf_ssh_key_pub = ${PCF_SSH_KEY_PUB}"
  echo "******************************"
  echo "pcf_ssh_key_priv = ${PCF_SSH_KEY_PRIV}"
  echo "******************************"
  echo "******************************"
fi

echo "=============================================================================================="
echo "Executing Terraform Plan ..."
echo "=============================================================================================="

terraform init "pcf-pipelines/install-pcf/azure/terraform/${AZURE_PCF_TERRAFORM_TEMPLATE}"

terraform plan \
  -var "subscription_id=${AZURE_SUBSCRIPTION_ID}" \
  -var "client_id=${AZURE_CLIENT_ID}" \
  -var "client_secret=${AZURE_CLIENT_SECRET}" \
  -var "tenant_id=${AZURE_TENANT_ID}" \
  -var "location=${AZURE_REGION}" \
  -var "env_name=${AZURE_TERRAFORM_PREFIX}" \
  -var "env_short_name=${ENV_SHORT_NAME}" \
  -var "azure_terraform_vnet_cidr=${AZURE_TERRAFORM_VNET_CIDR}" \
  -var "azure_terraform_subnet_infra_cidr=${AZURE_TERRAFORM_SUBNET_INFRA_CIDR}" \
  -var "azure_terraform_subnet_ert_cidr=${AZURE_TERRAFORM_SUBNET_ERT_CIDR}" \
  -var "azure_terraform_subnet_services1_cidr=${AZURE_TERRAFORM_SUBNET_SERVICES1_CIDR}" \
  -var "azure_terraform_subnet_dynamic_services_cidr=${AZURE_TERRAFORM_SUBNET_DYNAMIC_SERVICES_CIDR}" \
  -var "ert_subnet_id=${ERT_SUBNET}" \
  -var "pcf_ert_domain=${PCF_ERT_DOMAIN}" \
  -var "system_domain=${SYSTEM_DOMAIN}" \
  -var "apps_domain=${APPS_DOMAIN}" \
  -var "ops_manager_image_uri=${PCF_OPSMAN_IMAGE_URI}" \
  -var "vm_admin_username=${AZURE_VM_ADMIN}" \
  -var "vm_admin_public_key=${PCF_SSH_KEY_PUB}" \
  -var "azure_multi_resgroup_network=${AZURE_MULTI_RESGROUP_NETWORK}" \
  -var "azure_multi_resgroup_pcf=${AZURE_MULTI_RESGROUP_PCF}" \
  -var "azure_opsman_priv_ip=${AZURE_TERRAFORM_OPSMAN_PRIV_IP}" \
  -var "azure_account_name=${AZURE_ACCOUNT_NAME}" \
  -var "azure_buildpacks_container=${AZURE_BUILDPACKS_CONTAINER}" \
  -var "azure_droplets_container=${AZURE_DROPLETS_CONTAINER}" \
  -var "azure_packages_container=${AZURE_PACKAGES_CONTAINER}" \
  -var "azure_resources_container=${AZURE_RESOURCES_CONTAINER}" \
  -var "om_disk_size_in_gb=${PCF_OPSMAN_DISK_SIZE_IN_GB}" \
  -out terraform.tfplan \
  -state terraform-state/terraform.tfstate \
  "pcf-pipelines/install-pcf/azure/terraform/${AZURE_PCF_TERRAFORM_TEMPLATE}"

echo "=============================================================================================="
echo "Executing Terraform Apply ..."
echo "=============================================================================================="

terraform apply \
  -state-out terraform-state-output/terraform.tfstate \
  terraform.tfplan
