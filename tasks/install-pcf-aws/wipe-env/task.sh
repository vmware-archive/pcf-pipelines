#!/bin/bash
set -e

root=$(pwd)

cd pcf-pipelines/install-pcf/aws/terraform

echo "Checking for existence of ops manager..."
if [[ $(dig +nocmd ${OPSMAN_URI} +noall +answer | wc -l) -ne 0 ]]; then 
  echo "Deleting PCF installation..."
  om-linux \
    --target "https://${OPSMAN_URI}" \
    --skip-ssl-validation \
    --username $OPSMAN_USERNAME \
    --password $OPSMAN_PASSWORD \
    delete-installation
else
  echo "No ops manager could be found."
fi

export AWS_ACCESS_KEY_ID=${TF_VAR_aws_access_key}
export AWS_SECRET_ACCESS_KEY=${TF_VAR_aws_secret_key}
export AWS_DEFAULT_REGION=${TF_VAR_aws_region}

terraform destroy \
  -force \
  -var "opsman_ami=dontcare" \
  -var "db_master_username=dontcare" \
  -var "db_master_password=dontcare" \
  -var "prefix=dontcare" \
  -state "${root}/terraform-state/terraform.tfstate" \
  -state-out "${root}/terraform-state-output/terraform.tfstate"
