#!/bin/bash
set -e

root=$(pwd)

source "${root}/pcf-pipelines/functions/check_opsman_available.sh"

opsman_available=$(check_opsman_available $OPSMAN_URI)
if [[ $opsman_available == "available" ]]; then
  om-linux \
    --target "https://${OPSMAN_URI}" \
    --skip-ssl-validation \
    --username $OPSMAN_USERNAME \
    --password $OPSMAN_PASSWORD \
    delete-installation
fi
