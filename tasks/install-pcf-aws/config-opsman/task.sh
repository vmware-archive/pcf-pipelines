#!/bin/bash
set -e

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo "Configuring OpsManager @ https://opsman.$ERT_DOMAIN ..."
echo "=============================================================================================="

#Configure Opsman
om-linux --target https://opsman.$ERT_DOMAIN -k \
     configure-authentication \
       --username "$OPSMAN_USER" \
       --password "$OPSMAN_PASSWORD" \
       --decryption-passphrase "$OPSMAN_PASSWORD"
