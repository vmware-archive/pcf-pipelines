#!/bin/bash
set -e

source "pcf-pipelines/functions/check_opsman_available.sh"

opsman_available=$(check_opsman_available "opsman.${pcf_ert_domain}")
if [[ $opsman_available != "available" ]]; then
  echo Could not reach opsman.${pcf_ert_domain}. Is DNS set up correctly?
  exit 1
fi
