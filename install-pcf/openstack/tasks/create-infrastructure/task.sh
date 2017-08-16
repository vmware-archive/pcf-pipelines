#!/bin/bash

set -eu

ROOT=$PWD

function main() {
  terraform plan \
    -var "os_tenant_name=${OS_PROJECT_NAME}" \
    -var "os_username=${OS_USERNAME}" \
    -var "os_password=${OS_PASSWORD}" \
    -var "os_auth_url=${OS_AUTH_URL}" \
    -var "os_region=${OS_REGION_NAME}" \
    -var "os_domain_name=${OS_USER_DOMAIN_NAME}" \
    -var "prefix=${OS_RESOURCE_PREFIX}" \
    -var "infra_subnet_cidr=${INFRA_SUBNET_CIDR}" \
    -var "ert_subnet_cidr=${ERT_SUBNET_CIDR}" \
    -var "services_subnet_cidr=${SERVICES_SUBNET_CIDR}" \
    -var "dynamic_services_subnet_cidr=${DYNAMIC_SERVICES_SUBNET_CIDR}" \
    -var "infra_dns=${INFRA_DNS}" \
    -var "ert_dns=${ERT_DNS}" \
    -var "services_dns=${SERVICES_DNS}" \
    -var "dynamic_services_dns=${DYNAMIC_SERVICES_DNS}" \
    -var "external_network_id=${EXTERNAL_NETWORK_ID}" \
    -out "terraform.tfplan" \
    -state "terraform-state/terraform.tfstate" \
    "$ROOT/pcf-pipelines/install-pcf/openstack/terraform"

  terraform apply \
    -state-out "$ROOT/create-infrastructure-output/terraform.tfstate" \
    -parallelism=5 \
    terraform.tfplan
}

main
