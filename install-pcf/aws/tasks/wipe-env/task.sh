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

# Terminate all OpsMen before terraforming
aws configure << EOF
$AWS_ACCESS_KEY_ID
$AWS_SECRET_ACCESS_KEY
$AWS_REGION
json
EOF

aws_vpc_id=$(jq -r '.modules[0].outputs.vpc_id.value' $root/terraform-state/terraform.tfstate)
opsman_identifier=$(jq -r '.modules[0].outputs.opsman_identifier.value' $root/terraform-state/terraform.tfstate)

opsman_instance_ids=$(
  aws ec2 describe-instances --filters "Name=vpc-id,Values=$aws_vpc_id" "Name=tag:Name,Values=\"$opsman_identifier\"" | \
    jq -r '.Reservations[].Instances[].InstanceId'
)

if [ -n "$opsman_instance_ids" ]; then
  echo "Terminating $opsman_identifier with the following instance ids:" $opsman_instance_ids
  aws ec2 terminate-instances --instance-ids $opsman_instance_ids
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
