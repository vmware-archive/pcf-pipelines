#!/bin/bash
set -e

om-linux --target "https://opsman.${pcf_ert_domain}" -k \
  --username "$pcf_opsman_admin_username" \
  --password "$pcf_opsman_admin_password" \
  apply-changes
