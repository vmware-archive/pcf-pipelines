#!/bin/bash
set -e

om-linux \
  --target "https://opsman.${pcf_ert_domain}" \
  --skip-ssl-validation \
  configure-authentication \
  --username "$pcf_opsman_admin_username" \
  --password "$pcf_opsman_admin_password" \
  --decryption-passphrase "$pcf_opsman_admin_password"
