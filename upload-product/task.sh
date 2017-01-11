#!/bin/bash -exu

function main() {
  local cwd
  cwd="${1}"

  local product
  product="$(ls -1 "${cwd}"/product/*.pivotal)"

  om --target "${OPSMAN_URI}" \
     --skip-ssl-validation \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
     upload-product \
     --product ${product}
}

main "${PWD}"
