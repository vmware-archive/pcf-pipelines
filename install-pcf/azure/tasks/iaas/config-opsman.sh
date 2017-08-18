#!/bin/bash
set -e

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo "Configuring OpsManager @ https://opsman.${PCF_ERT_DOMAIN} ..."
echo "=============================================================================================="

#Configure Opsman
om-linux --target https://opsman.${PCF_ERT_DOMAIN} -k \
  configure-authentication \
  --username "${PCF_OPSMAN_ADMIN}" \
  --password "${PCF_OPSMAN_ADMIN_PASSWORD}" \
  --decryption-passphrase "${PCF_OPSMAN_ADMIN_PASSWORD}"
