#!/bin/bash
set -e

echo "=============================================================================================="
echo "Deploying Director @ https://${OPSMAN_DOMAIN_OR_IP_ADDRESS} ..."
echo "=============================================================================================="

# Apply Changes in Opsman

om-linux --target https://${OPSMAN_DOMAIN_OR_IP_ADDRESS} -k \
  --username "${PCF_OPSMAN_ADMIN}" \
  --password "${PCF_OPSMAN_ADMIN_PASSWORD}" \
  apply-changes
