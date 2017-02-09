#!/bin/bash -eu

function main() {

  chmod +x tool-om/om-linux
  CMD_PATH="tool-om/om-linux"

  local cwd
  cwd="${1}"

  ./${CMD_PATH} --target "${OPSMAN_URI}" \
     --skip-ssl-validation \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
     --request-timeout 6000 \
     export-installation --output-file "${OPSMAN_SETTINGS_FILENAME}"

   mv "${OPSMAN_SETTINGS_FILENAME}" ./opsmgr-settings
   echo "${OPSMAN_SETTINGS_FILENAME} moved to opsmgr-settings directory."

   ./${CMD_PATH} --target "${OPSMAN_URI}" \
     --skip-ssl-validation \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
     curl --path /api/v0/diagnostic_report \
     > "${cwd}/diagnostic-report/exported-diagnostic-report.json"
}

main "${PWD}"
