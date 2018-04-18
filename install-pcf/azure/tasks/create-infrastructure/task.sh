#!/usr/bin/env bash

set -eu

echo "=============================================================================================="
echo "Collecting Terraform Variables from Deployed Azure Objects ...."
echo "=============================================================================================="

# Get Opsman VHD from previous task
PCF_OPSMAN_IMAGE_URI=$(cat opsman-metadata/uri)

# Use prefix to strip down a Storage Account Prefix String
ENV_SHORT_NAME=$(echo ${AZURE_TERRAFORM_PREFIX} | tr -d "-" | tr -d "_" | tr -d "[0-9]")
ENV_SHORT_NAME=$(echo ${ENV_SHORT_NAME:0:10})

# Create a terraform var file. This var file is used by all later terraform commands
echo "subscription_id=\"$AZURE_SUBSCRIPTION_ID\"" >> terraform-vars-output/terraform.tfvars
echo "tenant_id=\"$AZURE_TENANT_ID\"" >> terraform-vars-output/terraform.tfvars
echo "client_id=\"$AZURE_CLIENT_ID\"" >> terraform-vars-output/terraform.tfvars
echo "client_secret=\"$AZURE_CLIENT_SECRET\"" >> terraform-vars-output/terraform.tfvars
echo "env_name=\"$AZURE_TERRAFORM_PREFIX\"" >> terraform-vars-output/terraform.tfvars
echo "env_short_name=\"$ENV_SHORT_NAME\"" >> terraform-vars-output/terraform.tfvars
echo "ops_manager_image_uri=\"$PCF_OPSMAN_IMAGE_URI\"" >> terraform-vars-output/terraform.tfvars
echo "location=\"$AZURE_REGION\"" >> terraform-vars-output/terraform.tfvars
echo "dns_suffix=\"$PCF_ERT_DOMAIN\"" >> terraform-vars-output/terraform.tfvars
echo "cf_storage_account_name=\"$AZURE_TERRAFORM_VNET_CIDR\"" >> terraform-vars-output/terraform.tfvars
echo "cf_buildpacks_storage_container_name=\"$AZURE_DROPLETS_CONTAINER\"" >> terraform-vars-output/terraform.tfvars
echo "cf_packages_storage_container_name=\"$AZURE_PACKAGES_CONTAINER\"" >> terraform-vars-output/terraform.tfvars
echo "cf_droplets_container_name=\"$AZURE_RESOURCES_CONTAINER\"" >> terraform-vars-output/terraform.tfvars
echo "cf_resources_container_name=\"$AZURE_BUILDPACKS_CONTAINER\"" >> terraform-vars-output/terraform.tfvars
echo "cf_storage_account_name=\"$AZURE_STORAGE_ACCOUNT_NAME\"" >> terraform-vars-output/terraform.tfvars
echo "pcf_dynamic_services_subnet=\"$AZURE_TERRAFORM_SUBNET_DYNAMIC_SERVICES_CIDR\"" >> terraform-vars-output/terraform.tfvars
echo "pcf_pas_subnet=\"$AZURE_TERRAFORM_SUBNET_PAS_CIDR\"" >> terraform-vars-output/terraform.tfvars
echo "pcf_management_subnet=\"$AZURE_TERRAFORM_SUBNET_INFRA_CIDR\"" >> terraform-vars-output/terraform.tfvars
echo "pcf_services_subnet=\"$AZURE_TERRAFORM_SUBNET_SERVICES_CIDR\"" >> terraform-vars-output/terraform.tfvars
echo "ops_manager_private_ip=\"$AZURE_OPSMAN_PRIV_IP\"" >> terraform-vars-output/terraform.tfvars


echo "=============================================================================================="
echo "Executing Terraform Plan ..."
echo "=============================================================================================="

terraform init "/home/vcap/app/terraforming-azure"

terraform plan \
  -var-file "terraform-vars-output/terraform.tfvars" \
  -out terraform.tfplan \
  -state terraform-state/terraform.tfstate \
  "/home/vcap/app/terraforming-azure"

echo "=============================================================================================="
echo "Executing Terraform Apply ..."
echo "=============================================================================================="

terraform apply \
  -state-out terraform-state-output/terraform.tfstate \
  terraform.tfplan
