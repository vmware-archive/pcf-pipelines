#!/bin/bash
set -e

chmod +x tool-om/om-linux

./tool-om/om-linux --target "https://opsman.${pcf_ert_domain}" -k \
  --username "$pcf_opsman_admin_username" \
  --password "$pcf_opsman_admin_password" \
  apply-changes
