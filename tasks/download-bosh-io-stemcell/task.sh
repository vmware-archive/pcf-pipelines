#!/bin/bash -eu

function main() {
  local cwd
  cwd="${1}"

  local product_file
  product_file="$(ls -1 ${cwd}/pivnet-product/*.pivotal)"

  chmod +x stemcell-downloader/stemcell-downloader-linux

  ./stemcell-downloader/stemcell-downloader-linux \
    --iaas-type "${IAAS_TYPE}" \
    --product-file "${product_file}" \
    --product-name "${PRODUCT}" \
    --download-dir "${cwd}/stemcell"
}

main "${PWD}"
