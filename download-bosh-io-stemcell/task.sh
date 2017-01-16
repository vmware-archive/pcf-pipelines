#!/bin/bash -exu

function main() {
  local cwd
  cwd="${1}"

  local product_file
  product_file="$(ls -1 ${cwd}/pivnet-product/*.pivotal)"

  local product_name
  if [[ -n ${PRODUCT} ]]; then
    product_name=${PRODUCT}
  else
    product_name="cf"
  fi

  ./download-bosh-io-stemcell/download-bosh-io-stemcell \
    --iaas-type "${IAAS_TYPE}" \
    --product-file "${product_file}" \
    --product-name "${product_name}" \
    --download-dir "${cwd}/stemcell"
}

main "${PWD}"
