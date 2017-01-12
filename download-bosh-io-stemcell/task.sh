#!/bin/bash -exu

function main() {
  local cwd
  cwd="${1}"

  local product_file
  product_file="$(ls -1 ${cwd}/ert-product/*.pivotal)"

  local product_name
  if [[ -n ${PRODUCT} ]]; then
    product_name=${PRODUCT}
  else
    product_name="cf"
  fi

  export GOPATH="${cwd}/go"
  pushd "${GOPATH}/src/github.com/pivotal-cf/pcf-releng-ci/tasks/future/download-bosh-io-stemcell" > /dev/null
    go run main.go \
      --iaas-type "${IAAS_TYPE}" \
      --product-file "${product_file}" \
      --product-name "${product_name}" \
      --download-dir "${cwd}/stemcell"
  popd > /dev/null
}

main "${PWD}"
