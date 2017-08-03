#!/bin/bash
set -e

ROOT=${PWD}

if [ $arg_wipe == "wipe" ]; then
  echo "Wiping Environment...."
else
  echo "Need Args [0]=wipe, anything else and I swear I'll exit and do nothing!!! "
  echo "Example: ./wipe-env.sh wipe ..."
  exit 0
fi

az login --service-principal -u ${azure_service_principal_id} -p ${azure_service_principal_password} --tenant ${azure_tenant_id}
az account set --subscription ${azure_subscription_id}

# Test if Resource Group exists,  if so then wipe it!!!
get_res_group_cmd="az group list --output json | jq '.[] | select(.name == \"${azure_terraform_prefix}\") | .' | jq .name | tr -d '\"'"
get_res_group=$(eval ${get_res_group_cmd})
if [[ ${get_res_group} = ${azure_terraform_prefix} ]]; then
    echo "Found Resource Group to Remove ....."
    az group delete --name ${azure_terraform_prefix} --yes
fi

# Clear terraform.tfstate
mkdir -p ${ROOT}/terraform-state-output
echo "{}" > ${ROOT}/terraform-state-output/terraform.tfstate
