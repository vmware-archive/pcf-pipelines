#!/bin/bash

azure_terraform_prefix=${1}

get_res_group_cmd="azure group list --json | jq '.[] | select(.name == \"${azure_terraform_prefix}\") | .' | jq .name | tr -d '\"'"
get_res_group=$(eval ${get_res_group_cmd})
if [[ ${get_res_group} = ${azure_terraform_prefix} ]]; then
    echo "Found Resource Group to Remove ....."
    azure group delete --name ${azure_terraform_prefix} --quiet
fi

azure group create ${1} -l eastus

azure group deployment create -f networking-resgroup.json -g ${1}
