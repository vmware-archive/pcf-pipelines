#!/bin/bash
set -e

unzip terraform-zip/terraform.zip -d terraform-zip
export PATH=$PWD/terraform-zip:$PATH

python get-pip/get-pip.py
pip install awscli

root=$(pwd)

cd pcf-pipelines/tasks/install-pcf-aws/terraform

export AWS_ACCESS_KEY_ID=${TF_VAR_aws_access_key}
export AWS_SECRET_ACCESS_KEY=${TF_VAR_aws_secret_key}
export AWS_DEFAULT_REGION=${TF_VAR_aws_region}
export VPC_ID=$(
  terraform state show -state "${root}/terraform-state/terraform.tfstate" aws_vpc.PcfVpc | grep ^id | awk '{print $3}'
)

#Clean AWS instances
instances=$(aws ec2 describe-instances --filters Name=vpc-id,Values=$VPC_ID --output=json | jq -r '.[] | .[] | .Instances | .[] | .InstanceId')
if [[ "X$instances" != "X" ]]
then
  echo "instances: $instances will be deleted......"
  aws ec2 terminate-instances --instance-ids $instances
  aws ec2 wait instance-terminated --instance-ids $instances
fi

set +e
terraform destroy \
  -force \
  -state "${root}/terraform-state/terraform.tfstate" \
  -state-out "${root}/terraform-state-output/terraform.tfstate"
