#!/bin/bash
set -ex
unzip terraform-zip/terraform.zip
mv terraform-zip/terraform /usr/local/bin
CWD=$(pwd)
cd pcf-pipelines/tasks/install-pcf-aws/terraform/

terraform plan

set +e
terraform apply
ret_code=$?

cp terraform.tfstate $CWD/pcfawsops-terraform-state-put/terraform.tfstate
exit $ret_code
