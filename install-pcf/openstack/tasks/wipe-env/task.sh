#!/bin/bash
set -e

root=$PWD

source "${root}/pcf-pipelines/functions/check_opsman_available.sh"

opsman_available=$(check_opsman_available $OPSMAN_URI)
if [[ $opsman_available == "available" ]]; then
  om-linux \
    --target https://$OPSMAN_URI \
    --skip-ssl-validation \
    --username "$OPSMAN_USERNAME" \
    --password "$OPSMAN_PASSWORD" \
    delete-installation
fi

terraform init pcf-pipelines/install-pcf/openstack/terraform

echo "Deleting provisioned infrastructure..."
terraform destroy -force \
  -var "os_tenant_name=${OS_PROJECT_NAME}" \
  -var "os_username=${OS_USERNAME}" \
  -var "os_password=${OS_PASSWORD}" \
  -var "os_auth_url=${OS_AUTH_URL}" \
  -var "os_region=${OS_REGION_NAME}" \
  -var "os_domain_name=${OS_USER_DOMAIN_NAME}" \
  -var "prefix=dontcare" \
  -var "infra_subnet_cidr=dontcare" \
  -var "ert_subnet_cidr=dontcare" \
  -var "services_subnet_cidr=dontcare" \
  -var "dynamic_services_subnet_cidr=dontcare" \
  -var "infra_dns=dontcare" \
  -var "opsman_fixed_ip=dontcare" \
  -var "ert_dns=dontcare" \
  -var "services_dns=dontcare" \
  -var "dynamic_services_dns=dontcare" \
  -var "external_network=dontcare" \
  -var "external_network_id=dontcare" \
  -var "opsman_image_name=dontcare" \
  -var "opsman_public_key=dontcare" \
  -var "opsman_volume_size=50" \
  -var "opsman_flavor=dontcare" \
  -state "$root/terraform-state/terraform.tfstate" \
  -state-out $root/wipe-output/terraform.tfstate \
  pcf-pipelines/install-pcf/openstack/terraform
