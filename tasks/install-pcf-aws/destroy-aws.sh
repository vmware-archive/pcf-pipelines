#!/bin/bash
set -e
mv /opt/terraform/terraform /usr/local/bin
CWD=$(pwd)
cd pcf-pipelines/tasks/install-pcf-aws/terraform/
cp $CWD/pcfawsops-terraform-state-get/terraform.tfstate .

export AWS_ACCESS_KEY_ID=${TF_VAR_aws_access_key}
export AWS_SECRET_ACCESS_KEY=${TF_VAR_aws_secret_key}
export AWS_DEFAULT_REGION=${TF_VAR_aws_region}
export VPC_ID=`terraform state show aws_vpc.PcfVpc | grep ^id | awk '{print $3}'`

#Clean AWS instances
pip install awscli

instances=$(aws ec2 describe-instances --filters Name=vpc-id,Values=$VPC_ID --output=json | jq -r '.[] | .[] | .Instances | .[] | .InstanceId')
if [[ "X$instances" != "X" ]]
then
  echo "instances: $instances will be deleted......"
  aws ec2 terminate-instances --instance-ids $instances
  aws ec2 wait instance-terminated --instance-ids $instances
fi

#Destroy the plan
terraform plan
set +e
terraform destroy -force

cd $CWD/pcfawsops-terraform-state-put
touch terraform.tfstate
