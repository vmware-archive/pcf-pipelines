#!/bin/bash -e

function main() {
  local file_to_migrate=${1}

  if [[ ! -f "${file_to_migrate}" ]]; then
    echo "Usage: ${0} <path-to-aws-param.yml>"
    echo "Migrates an aws install-pcf yaml param file that is compatible with pcf-pipeline v0.19.2."
    exit 1
  fi

  local params="$(cat ${file_to_migrate})"

  params="$(migrate "${params}" "TF_VAR_aws_access_key" "aws_access_key_id")"
  params="$(migrate "${params}" "TF_VAR_aws_secret_key" "aws_secret_access_key")"
  params="$(migrate "${params}" "TF_VAR_aws_cert_arn" "aws_cert_arn")"
  params="$(migrate "${params}" "TF_VAR_amis_nat" "amis_nat")"
  params="$(migrate "${params}" "TF_VAR_aws_region" "aws_region")"
  params="$(migrate "${params}" "TF_VAR_az1" "aws_az1")"
  params="$(migrate "${params}" "TF_VAR_az2" "aws_az2")"
  params="$(migrate "${params}" "TF_VAR_az3" "aws_az3")"
  params="$(migrate "${params}" "OPSMAN_PASSWORD" "opsman_admin_username")"
  params="$(migrate "${params}" "OPSMAN_USER" "opsman_admin_password")"
  params="$(migrate "${params}" "TF_VAR_aws_key_name" "aws_key_name")"
  params="$(migrate "${params}" "TF_VAR_vpc_cidr" "vpc_cidr")"
  params="$(migrate "${params}" "TF_VAR_public_subnet_cidr_az1" "public_subnet_cidr_az1")"
  params="$(migrate "${params}" "TF_VAR_public_subnet_cidr_az2" "public_subnet_cidr_az2")"
  params="$(migrate "${params}" "TF_VAR_public_subnet_cidr_az3" "public_subnet_cidr_az3")"
  params="$(migrate "${params}" "TF_VAR_ert_subnet_cidr_az1" "ert_subnet_cidr_az1")"
  params="$(migrate "${params}" "TF_VAR_ert_subnet_cidr_az2" "ert_subnet_cidr_az2")"
  params="$(migrate "${params}" "TF_VAR_ert_subnet_cidr_az3" "ert_subnet_cidr_az3")"
  params="$(migrate "${params}" "TF_VAR_services_subnet_cidr_az1" "services_subnet_cidr_az1")"
  params="$(migrate "${params}" "TF_VAR_services_subnet_cidr_az2" "services_subnet_cidr_az2")"
  params="$(migrate "${params}" "TF_VAR_services_subnet_cidr_az3" "services_subnet_cidr_az3")"
  params="$(migrate "${params}" "TF_VAR_dynamic_services_subnet_cidr_az1" "dynamic_services_subnet_cidr_az1")"
  params="$(migrate "${params}" "TF_VAR_dynamic_services_subnet_cidr_az2" "dynamic_services_subnet_cidr_az2")"
  params="$(migrate "${params}" "TF_VAR_dynamic_services_subnet_cidr_az3" "dynamic_services_subnet_cidr_az3")"
  params="$(migrate "${params}" "TF_VAR_infra_subnet_cidr_az1" "infra_subnet_cidr_az1")"
  params="$(migrate "${params}" "TF_VAR_rds_subnet_cidr_az1" "rds_subnet_cidr_az1")"
  params="$(migrate "${params}" "TF_VAR_rds_subnet_cidr_az2" "rds_subnet_cidr_az2")"
  params="$(migrate "${params}" "TF_VAR_rds_subnet_cidr_az3" "rds_subnet_cidr_az3")"
  params="$(migrate "${params}" "TF_VAR_opsman_ip_az1" "opsman_ip_az1")"
  params="$(migrate "${params}" "TF_VAR_nat_ip_az1" "nat_ip_az1")"
  params="$(migrate "${params}" "TF_VAR_nat_ip_az2" "nat_ip_az2")"
  params="$(migrate "${params}" "TF_VAR_nat_ip_az3" "nat_ip_az3")"

  echo "${params}"
}

function migrate() {
  local params="${1}"
  local old_param="${2}"
  local new_param="${3}"
  if [[ -z $(grep "^${old_param}:" <<< "${params}") ]]; then
    >&2 echo "\"${old_param}\" param not found. Make sure this param file is for the AWS install-pcf pipeline and is compatible with pcf-pipelines v0.19.2."
    exit 1
  fi

  sed -e "s/^${old_param}:/${new_param}:/g" <<< "${params}"
}

main ${@}
