#!/bin/bash

set -eu

root=$PWD

product_file="$(ls -1 ${root}/pivnet-product/*.pivotal)"

chmod +x stemcell-downloader/stemcell-downloader-linux

mkdir -p "${root}/stemcell"

./stemcell-downloader/stemcell-downloader-linux \
  --iaas-type "${IAAS_TYPE}" \
  --product-file "${product_file}" \
  --product-name "${PRODUCT}" \
  --download-dir "${root}/stemcell"

stemcell="$(ls -1 "${root}"/stemcell/*.tgz)"

chmod +x ./tool-om/om-linux

./tool-om/om-linux --target ${OPSMAN_URI} \
  --skip-ssl-validation \
  --username "${OPSMAN_USERNAME}" \
  --password "${OPSMAN_PASSWORD}" \
  upload-stemcell \
  --stemcell "${stemcell}"
