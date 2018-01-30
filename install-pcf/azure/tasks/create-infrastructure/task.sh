#!/bin/bash
set -e


if [[ ${AZURE_PCF_TERRAFORM_TEMPLATE} == "c0-azure-multi-res-group" ]]; then
  # Get ert subnet if multi-resgroup
  az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}
  az account set --subscription ${AZURE_SUBSCRIPTION_ID}

  INFRA_SUBNET_ID=$(
    az network vnet subnet list \
      --resource-group ${AZURE_MULTI_RESGROUP_NETWORK} \
      --vnet-name ${AZURE_MULTI_RESGROUP_INFRA_VNET_NAME}  \
    | jq -r '.[] | select(.name | contains( "opsman" )) | .id')
  echo "INFRA_SUBNET_ID=${INFRA_SUBNET_ID}"


  ERT_SUBNET_ID=$(
    az network vnet subnet list \
      --resource-group ${AZURE_MULTI_RESGROUP_NETWORK} \
      --vnet-name ${AZURE_MULTI_RESGROUP_INFRA_VNET_NAME}  \
    | jq -r '.[] | select(.name | contains( "ert" )) | .id')
  echo "ERT_SUBNET_ID=${ERT_SUBNET_ID}"


  PUB_IP_ID_PCF_LB=$(
    az network public-ip show \
      --name "${AZURE_TERRAFORM_PREFIX}-web-lb-public-ip" \
      --resource-group ${AZURE_MULTI_RESGROUP_NETWORK} \
    | jq -r '.id' )
  echo "PUB_IP_ID_PCF_LB=${PUB_IP_ID_PCF_LB}"

  PUB_IP_ID_TCP_LB=$(
    az network public-ip show \
      --name "${AZURE_TERRAFORM_PREFIX}-tcp-lb-public-ip" \
      --resource-group ${AZURE_MULTI_RESGROUP_NETWORK} \
    | jq -r '.id' )
  echo "PUB_IP_ID_TCP_LB=${PUB_IP_ID_TCP_LB}"

  PUB_IP_ID_SSH_PROXY_LB=$(
    az network public-ip show \
      --name "${AZURE_TERRAFORM_PREFIX}-ssh-proxy-lb-public-ip" \
      --resource-group ${AZURE_MULTI_RESGROUP_NETWORK} \
    | jq -r '.id' )
  echo "PUB_IP_ID_SSH_PROXY_LB=${PUB_IP_ID_SSH_PROXY_LB}"

  PUB_IP_ID_JUMPBOX_VM=$(
    az network public-ip show \
      --name "${AZURE_TERRAFORM_PREFIX}-jb-lb-public-ip" \
      --resource-group ${AZURE_MULTI_RESGROUP_NETWORK} \
    | jq -r '.id' )
  echo "PUB_IP_ID_JUMPBOX_VM=${PUB_IP_ID_JUMPBOX_VM}"

  PUB_IP_ID_OPSMAN_VM=$(
    az network public-ip show \
      --name "${AZURE_TERRAFORM_PREFIX}-opsman-public-ip" \
      --resource-group ${AZURE_MULTI_RESGROUP_NETWORK} \
    | jq -r '.id' )
  echo "PUB_IP_ID_OPSMAN_VM=${PUB_IP_ID_OPSMAN_VM}"

else
  INFRA_SUBNET_ID=""
  ERT_SUBNET_ID=""
  PUB_IP_ID_PCF_LB=""
  PUB_IP_ID_TCP_LB=""
  PUB_IP_ID_SSH_PROXY_LB=""
  PUB_IP_ID_JUMPBOX_VM=""
  PUB_IP_ID_OPSMAN_VM=""
fi


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
  -var "infra_subnet_id=${INFRA_SUBNET_ID}" \
  -var "ert_subnet_id=${ERT_SUBNET_ID}" \
  -var "pcf_ert_domain=${PCF_ERT_DOMAIN}" \
  -var "ops_manager_image_uri=${PCF_OPSMAN_IMAGE_URI}" \
  -var "vm_admin_username=${AZURE_VM_ADMIN}" \
  -var "vm_admin_public_key=${PCF_SSH_KEY_PUB}" \
  -var "azure_multi_resgroup_network=${AZURE_MULTI_RESGROUP_NETWORK}" \
  -var "azure_multi_resgroup_pcf=${AZURE_MULTI_RESGROUP_PCF}" \
  -var "priv_ip_opsman_vm=${AZURE_TERRAFORM_OPSMAN_PRIV_IP}" \
  -var "azure_account_name=${AZURE_ACCOUNT_NAME}" \
  -var "azure_buildpacks_container=${AZURE_BUILDPACKS_CONTAINER}" \
  -var "azure_droplets_container=${AZURE_DROPLETS_CONTAINER}" \
  -var "azure_packages_container=${AZURE_PACKAGES_CONTAINER}" \
  -var "azure_resources_container=${AZURE_RESOURCES_CONTAINER}" \
  -var "om_disk_size_in_gb=${PCF_OPSMAN_DISK_SIZE_IN_GB}" \
  -var "pub_ip_id_pcf_lb=${PUB_IP_ID_PCF_LB}" \
  -var "pub_ip_id_tcp_lb=${PUB_IP_ID_TCP_LB}" \
  -var "pub_ip_id_ssh_proxy_lb=${PUB_IP_ID_SSH_PROXY_LB}" \
  -var "pub_ip_id_jumpbox_vm=${PUB_IP_ID_JUMPBOX_VM}" \
  -var "pub_ip_id_opsman_vm=${PUB_IP_ID_OPSMAN_VM}" \
  -out terraform.tfplan \
  -state terraform-state/terraform.tfstate \
  "pcf-pipelines/install-pcf/azure/terraform/${AZURE_PCF_TERRAFORM_TEMPLATE}"

echo "=============================================================================================="
echo "Executing Terraform Apply ..."
echo "=============================================================================================="

terraform apply \
  -state-out terraform-state-output/terraform.tfstate \
  terraform.tfplan
