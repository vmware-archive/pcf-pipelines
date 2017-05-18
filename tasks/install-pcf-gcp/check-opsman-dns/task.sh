#!/bin/bash
set -e

if [[ -z $(dig +short "opsman.${pcf_ert_domain}") ]]; then
  echo "Could not reach opsman.${pcf_ert_domain}. Is DNS set up correctly?"
  exit 1
fi
