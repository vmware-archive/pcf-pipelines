#!/bin/bash
set -e

cd terraform-state
  db_host=$(terraform output --json -state *.tfstate | jq --raw-output '.sql_instance_ip.value')
cd -

if [ -z "$db_host" ]; then
  echo Failed to get SQL instance IP from Terraform state file
  exit 1
fi

sed -i \
  -e "s%{{pcf_ert_networking_pointofentry}}%${pcf_ert_networking_pointofentry}%g" \
  json_file/ert.json

if [[ "${azure_access_key}" != "" ]]; then
  json_file="json_file/ert.json"
  cat ${json_file} | jq \
    --arg azure_access_key "${azure_access_key}" \
    --arg azure_account_name "${ert_azure_account_name}" \
    --arg azure_buildpacks_container "${azure_buildpacks_container}" \
    --arg azure_droplets_container "${azure_droplets_container}" \
    --arg azure_packages_container "${azure_packages_container}" \
    --arg azure_resources_container "${azure_resources_container}" \
    '
    .properties.properties |= .+ {
      ".properties.system_blobstore.external_azure.access_key": {
        "value": {
          "secret": $azure_access_key
        }
      },
      ".properties.system_blobstore": {
        "value": "external_azure"
      },
      ".properties.system_blobstore.external_azure.account_name": {
        "value": $azure_account_name
      },
      ".properties.system_blobstore.external_azure.buildpacks_container": {
        "value": $azure_buildpacks_container
      },
      ".properties.system_blobstore.external_azure.droplets_container": {
        "value": $azure_droplets_container
      },
      ".properties.system_blobstore.external_azure.packages_container": {
        "value": $azure_packages_container
      },
      ".properties.system_blobstore.external_azure.resources_container": {
        "value": $azure_resources_container
      }
    }
    ' > /tmp/ert.json
  mv /tmp/ert.json ${json_file}
fi

