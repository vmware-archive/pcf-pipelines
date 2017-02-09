#!/bin/bash -eu

function main() {
  local cwd
  cwd="${1}"

  chmod +x tool-om/om-linux
  local om
  om="tool-om/om-linux"

  printf 'Waiting for opsman to come up'
  until $(curl --output /dev/null --silent --head --fail -k ${OPSMAN_URI}); do
    printf '.'
    sleep 5
  done

  om --target "${OPSMAN_URI}" \
     --skip-ssl-validation \
     import-installation \
     --installation "${cwd}/opsmgr-settings/${OPSMAN_SETTINGS_FILENAME}" \
     --decryption-passphrase "${OPSMAN_PASSPHRASE}"
 }

 main "${PWD}"
