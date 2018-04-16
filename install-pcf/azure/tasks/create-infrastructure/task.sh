#!/usr/bin/env bash
echo "=============================================================================================="
echo "Collecting Terraform Variables from Deployed Azure Objects ...."
echo "=============================================================================================="

# Get Opsman VHD from previous task
PCF_OPSMAN_IMAGE_URI=$(cat opsman-metadata/uri)

# Use prefix to strip down a Storage Account Prefix String
ENV_SHORT_NAME=$(echo ${AZURE_TERRAFORM_PREFIX} | tr -d "-" | tr -d "_" | tr -d "[0-9]")
ENV_SHORT_NAME=$(echo ${ENV_SHORT_NAME:0:10})


echo "=============================================================================================="
echo "Executing Terraform Plan ..."
echo "=============================================================================================="

terraform init "/home/vcap/app/terraforming-azure"

terraform plan \
  -var "subscription_id=$AZURE_SUBSCRIPTION_ID" \
  -var "tenant_id=$AZURE_TENANT_ID" \
  -var "client_id=$AZURE_CLIENT_ID" \
  -var "client_secret=$AZURE_CLIENT_SECRET" \
  -var "env_name=$AZURE_TERRAFORM_PREFIX" \
  -var "env_short_name=$ENV_SHORT_NAME" \
  -var "ops_manager_image_uri=$PCF_OPSMAN_IMAGE_URI" \
  -var "location=$AZURE_REGION" \
  -var "dns_suffix=$PCF_ERT_DOMAIN" \
  -out terraform.tfplan \
  -state terraform-state/terraform.tfstate \
  "/home/vcap/app/terraforming-azure"

echo "=============================================================================================="
echo "Executing Terraform Apply ..."
echo "=============================================================================================="

terraform apply \
  -state-out terraform-state-output/terraform.tfstate \
  terraform.tfplan

#Configure Opsman
om-linux --target https://${OPSMAN_DOMAIN_OR_IP_ADDRESS} -k \
  configure-authentication \
  --username "${PCF_OPSMAN_ADMIN}" \
  --password "${PCF_OPSMAN_ADMIN_PASSWORD}" \
  --decryption-passphrase "${PCF_OPSMAN_ADMIN_PASSWORD}"