#!/bin/bash -e

if [ -z "${TERRAFORM_ZIP_URL}" ]; then
  TERRAFORM_ZIP_URL="https://releases.hashicorp.com/terraform/0.8.6/terraform_0.8.6_linux_amd64.zip"
fi

wget -O terraform.zip ${TERRAFORM_ZIP_URL}

mkdir -p terraform/bin

unzip terraform.zip -d terraform/bin
