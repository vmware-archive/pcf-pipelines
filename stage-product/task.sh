#!/bin/bash -eu

function main() {

  chmod +x tool-om/om-linux
  CMD_PATH="tool-om/om-linux"

  local cwd
  cwd="${1}"

  local version
  pushd "${cwd}/pivnet-product"
    version="$(ls -1 *.pivotal | sed "s/"${PRODUCT_NAME}"-\(.*\).pivotal/\1/")"
  popd

  ./${CMD_PATH} --target "${OPSMAN_URI}" \
     --skip-ssl-validation \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
     stage-product \
     --product-name "${PRODUCT_NAME}" \
     --product-version "${version}"
}

main "${PWD}"
