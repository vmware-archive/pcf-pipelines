#!/bin/bash
set -e

echo "=============================================================================================="
echo "Configuring OpsManager @ https://opsman.${PCF_ERT_DOMAIN} ..."
echo "=============================================================================================="

#Configure Opsman
om-linux --target https://opsman.${PCF_ERT_DOMAIN} -k \
  configure-authentication \
  --username "${PCF_OPSMAN_ADMIN}" \
  --password "${PCF_OPSMAN_ADMIN_PASSWORD}" \
  --decryption-passphrase "${PCF_OPSMAN_ADMIN_PASSWORD}"
