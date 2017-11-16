#!/bin/bash -e

function main() {
  local file_to_migrate=${1}

  if [[ ! -f "${file_to_migrate}" ]]; then
    echo "Usage: ${0} <path-to-gcp-param.yml>"
    echo "Migrates an gcp install-pcf yaml param file that is compatible with pcf-pipeline v0.19.2."
    exit 1
  fi

  local params="$(cat ${file_to_migrate})"

  params="$(migrate "${params}" "pcf_opsman_admin_username" "opsman_admin_username")"
  params="$(migrate "${params}" "pcf_opsman_admin_password" "opsman_admin_password")"
  params="$(migrate "${params}" "pcf_opsman_trusted_certs" "opsman_trusted_certs")"

  echo "${params}"
}

function migrate() {
  local params="${1}"
  local old_param="${2}"
  local new_param="${3}"
  if [[ -z $(grep "^${old_param}:" <<< "${params}") ]]; then
    >&2 echo "\"${old_param}\" param not found. Make sure this param file is for the GCP install-pcf pipeline and is compatible with pcf-pipelines v0.19.2."
    exit 1
  fi

  sed -e "s/^${old_param}:/${new_param}:/g" <<< "${params}"
}

main ${@}
