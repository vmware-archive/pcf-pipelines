#!/bin/bash
set -ex

CWD=$(pwd)
cd pcf-pipelines/tasks/install-pcf-aws/terraform/

$CWD/terraform-bin/terraform plan

set +e
$CWD/terraform-bin/terraform apply
ret_code=$?

cp terraform.tfstate $CWD/terraform-state/terraform.tfstate
exit $ret_code
