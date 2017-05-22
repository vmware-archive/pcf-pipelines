#!/bin/bash
set -e

# TODO: Remove this
sudo apt-get update
sudo apt-get install -y --no-install-recommends python-dev
python get-pip/get-pip.py
pip install awscli

root=$(pwd)

cd pcf-pipelines/tasks/install-pcf-aws/terraform

export AWS_ACCESS_KEY_ID=${TF_VAR_aws_access_key}
export AWS_SECRET_ACCESS_KEY=${TF_VAR_aws_secret_key}
export AWS_DEFAULT_REGION=${TF_VAR_aws_region}
export VPC_ID=$(
  ./terraform-bin/terraform state show -state "${root}/terraform-state/terraform.tfstate" aws_vpc.PcfVpc | grep ^id | awk '{print $3}'
)

instances=$(
  aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" --output=json |
  jq --raw-output '.Reservations[].Instances[].InstanceId'
)
if [[ -n "$instances" ]]; then
  # Purge all BOSH-managed VMs from the VPC
  echo "instances: $instances will be deleted......"
  aws ec2 terminate-instances --instance-ids $instances
  aws ec2 wait instance-terminated --instance-ids $instances
fi

set +e
./terraform-bin/terraform destroy \
  -force \
  -state "${root}/terraform-state/terraform.tfstate" \
  -state-out "${root}/terraform-state-output/terraform.tfstate"
