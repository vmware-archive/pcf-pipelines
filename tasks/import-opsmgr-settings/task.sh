#!/bin/bash -eu

function main() {
  local cwd
  cwd="${1}"

  chmod +x tool-om/om-linux
  local om="tool-om/om-linux"

  printf "Waiting for %s to come up" "$OPSMAN_URI"
  until $(curl --output /dev/null --silent --head --fail -k ${OPSMAN_URI}); do
    printf '.'
    sleep 5
  done
  printf '\n'

  $om --target "${OPSMAN_URI}" \
      --skip-ssl-validation \
      import-installation \
      --installation "${cwd}/opsmgr-settings/${OPSMAN_SETTINGS_FILENAME}" \
      --decryption-passphrase "${OPSMAN_PASSPHRASE}"
 }

 main "${PWD}"
