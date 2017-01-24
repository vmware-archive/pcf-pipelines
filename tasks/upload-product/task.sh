#!/bin/bash -eu

function main() {

  chmod +x tool-om/om-linux
  CMD_PATH="tool-om/om-linux"

  local cwd
  cwd="${1}"

  local product
  product="$(ls -1 "${cwd}"/pivnet-product/*.pivotal)"

  ./${CMD_PATH} --target "${OPSMAN_URI}" \
     --skip-ssl-validation \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
     upload-product \
     --product ${product}
}

main "${PWD}"
