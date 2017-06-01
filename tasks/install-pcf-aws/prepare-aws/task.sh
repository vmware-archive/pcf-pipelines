#!/bin/bash

set -ex

ami=$(cat ami/ami)

terraform plan \
  -state terraform-state/terraform.tfstate \
  -var "opsman_ami=${ami}" \
  -out terraform.tfplan \
  pcf-pipelines/tasks/install-pcf-aws/terraform

terraform apply \
  -state-out terraform-state-output/terraform.tfstate \
  terraform.tfplan
