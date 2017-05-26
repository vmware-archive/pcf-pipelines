#!/bin/bash
set -e

echo "=============================================================================================="
echo "Configuring OpsManager @ https://opsman.$ERT_DOMAIN ..."
echo "=============================================================================================="

#Configure Opsman
om-linux --target https://opsman.$ERT_DOMAIN -k \
     configure-authentication \
       --username "$OPSMAN_USER" \
       --password "$OPSMAN_PASSWORD" \
       --decryption-passphrase "$OPSMAN_PASSWORD"
