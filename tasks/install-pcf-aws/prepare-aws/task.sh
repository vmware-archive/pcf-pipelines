#!/bin/bash

set -ex

terraform plan \
  -state terraform-state/terraform.tfstate \
  -out terraform.tfplan \
  pcf-pipelines/tasks/install-pcf-aws/terraform

terraform apply \
  -state-out terraform-state-output/terraform.tfstate \
  terraform.tfplan
