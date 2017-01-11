#!/bin/bash -exu

function main() {
  local cwd
  cwd="${1}"

  local version
  pushd "${cwd}/product"
    version="$(ls -1 *.pivotal | sed "s/"${PRODUCT}"-\(.*\).pivotal/\1/")"
  popd

  om --target "${OPSMAN_URI}" \
     --skip-ssl-validation \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
     stage-product \
     --product-name "${PRODUCT_NAME}" \
     --product-version "${version}"
}

main "${PWD}"
