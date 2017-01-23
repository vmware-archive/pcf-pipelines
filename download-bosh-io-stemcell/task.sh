#!/bin/bash -eu

function main() {
  local cwd
  cwd="${1}"

  local product_file
  product_file="$(ls -1 ${cwd}/pivnet-product/*.pivotal)"

  ./concourse-tasks-bundle/download-bosh-io-stemcell/download-bosh-io-stemcell \
    --iaas-type "${IAAS_TYPE}" \
    --product-file "${product_file}" \
    --product-name "${PRODUCT}" \
    --download-dir "${cwd}/stemcell"
}

main "${PWD}"
