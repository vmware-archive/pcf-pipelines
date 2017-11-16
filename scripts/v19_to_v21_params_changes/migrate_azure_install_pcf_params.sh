#!/bin/bash -e

function main() {
  local file_to_migrate=${1}

  if [[ ! -f "${file_to_migrate}" ]]; then
    echo "Usage: ${0} <path-to-azure-param.yml>"
    echo "Migrates an azure install-pcf yaml param file that is compatible with pcf-pipeline v0.19.2."
    exit 1
  fi

  local params="$(cat ${file_to_migrate})"

  params="$(migrate "${params}" "pcf_opsman_admin_username" "opsman_admin_username")"
  params="$(migrate "${params}" "pcf_opsman_admin_password" "opsman_admin_password")"
  params="$(migrate "${params}" "terraform_statefile_container" "azure_storage_container_name")"
  params="$(migrate "${params}" "azure_service_principal_id" "azure_client_id")"
  params="$(migrate "${params}" "azure_service_principal_password" "azure_client_secret")"

  echo "${params}"
}

function migrate() {
  local params="${1}"
  local old_param="${2}"
  local new_param="${3}"
  if [[ -z $(grep "^${old_param}:" <<< "${params}") ]]; then
    >&2 echo "\"${old_param}\" param not found. Make sure this param file is for the Azure install-pcf pipeline and is compatible with pcf-pipelines v0.19.2."
    exit 1
  fi

  sed -e "s/^${old_param}:/${new_param}:/g" <<< "${params}"
}

main ${@}
