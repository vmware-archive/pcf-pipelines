#!/bin/bash
set -e

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo "Configuring OpsManager @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="


#Configure Opsman
om-linux --target https://opsman.$pcf_ert_domain -k \
     configure-authentication \
       --username "$pcf_opsman_admin" \
       --password "$pcf_opsman_admin_passwd" \
       --decryption-passphrase "$pcf_opsman_admin_passwd"
