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
     export-installation --output-file "${OPSMAN_SETTINGS_FILENAME}"

   mv "${OPSMAN_SETTINGS_FILENAME}" ./opsmgr-settings
   echo "${OPSMAN_SETTINGS_FILENAME} moved to opsmgr-settings directory."
}

main "${PWD}"
