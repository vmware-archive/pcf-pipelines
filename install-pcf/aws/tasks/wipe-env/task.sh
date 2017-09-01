#!/bin/bash
set -eu

root=$(pwd)

cd pcf-pipelines/install-pcf/aws/terraform

source "${root}/pcf-pipelines/functions/check_opsman_available.sh"

opsman_available=$(check_opsman_available $OPSMAN_DOMAIN_OR_IP_ADDRESS)
if [[ $opsman_available == "available" ]]; then
  om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username $OPSMAN_USERNAME \
    --password $OPSMAN_PASSWORD \
    delete-installation
fi

terraform destroy \
  -force \
  -var "aws_access_key=${AWS_ACCESS_KEY_ID}" \
  -var "aws_secret_key=${AWS_SECRET_ACCESS_KEY}" \
  -var "aws_region=${AWS_REGION}" \
  -var "aws_key_name=dontcare" \
  -var "aws_cert_arn=dontcare" \
  -var "db_master_username=dontcare" \
  -var "db_master_password=dontcare" \
  -var "prefix=dontcare" \
  -var "opsman_ami=dontcare" \
  -var "amis_nat=dontcare" \
  -var "az1=dontcare" \
  -var "az2=dontcare" \
  -var "az3=dontcare" \
  -var "route53_zone_id=dontcare" \
  -state "${root}/terraform-state/terraform.tfstate" \
  -state-out "${root}/terraform-state-output/terraform.tfstate"
