#!/bin/bash -e

function main() {
  local file_to_migrate=${1}

  if [[ ! -f "${file_to_migrate}" ]]; then
    echo "Usage: ${0} <path-to-vsphere-param.yml>"
    echo "Migrates an vsphere install-pcf yaml param file that is compatible with pcf-pipeline v0.19.2."
    exit 1
  fi

  local params="$(cat ${file_to_migrate})"

  params="$(migrate "${params}" "om_ssh_pwd" "opsman_ssh_password")"
  params="$(migrate "${params}" "vcenter_data_center" "vcenter_datacenter")"
  params="$(migrate "${params}" "om_data_store" "vcenter_datastore")"
  params="$(append_param "${params}" "vcenter_ca_cert")"
  params="$(append_param "${params}" "vcenter_insecure")"

  echo "${params}"
}

function migrate() {
  local params="${1}"
  local old_param="${2}"
  local new_param="${3}"
  if [[ -z $(grep "^${old_param}:" <<< "${params}") ]]; then
    >&2 echo "\"${old_param}\" param not found. Make sure this param file is for the vSphere install-pcf pipeline and is compatible with pcf-pipelines v0.19.2."
    exit 1
  fi

  sed -e "s/^${old_param}:/${new_param}:/g" <<< "${params}"
}

function append_param() {
  local params="${1}"
  local new_param="${2}"
  echo "${params}"
  if [[ -z $(grep "^${new_param}:" <<< "${params}") ]]; then
    echo "${new_param}: "
  fi
}

main ${@}
