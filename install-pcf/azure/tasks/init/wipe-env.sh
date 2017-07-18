#!/bin/bash
set -e


if [ $arg_wipe == "wipe" ];
        then
                echo "Wiping Environment...."
        else
                echo "Need Args [0]=wipe, anything else and I swear I'll exit and do nothing!!! "
                echo "Example: ./wipe-env.sh wipe ..."
                exit 0
fi

azure login --service-principal -u ${azure_service_principal_id} -p ${azure_service_principal_password} --tenant ${azure_tenant_id}
azure account set ${azure_subscription_id}

if [[ ! -z ${azure_multi_resgroup_pcf} && ${azure_pcf_terraform_template} == "c0-azure-multi-res-group" ]]; then
    azure_terraform_prefix=${azure_multi_resgroup_pcf}
fi

# Test if Resource Group exists,  if so then wipe it!!!
get_res_group_cmd="azure group list --json | jq '.[] | select(.name == \"${azure_terraform_prefix}\") | .' | jq .name | tr -d '\"'"
get_res_group=$(eval ${get_res_group_cmd})
if [[ ${get_res_group} = ${azure_terraform_prefix} ]]; then
    echo "Found Resource Group to Remove ....."
    azure group delete --subscription ${azure_subscription_id} --name ${azure_terraform_prefix} --quiet
fi
