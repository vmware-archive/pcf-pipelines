#!/bin/bash -eu

function main() {
  local cwd
  cwd="${1}"

  chmod +x tool-om/om-linux
  local om="tool-om/om-linux"

  for stemcell in ${cwd}/stemcells/*.tgz; do
    printf "Uploading %s to %s ...\n" "${stemcell}" "${OPSMAN_URI}"
    $om --target "${OPSMAN_URI}" \
        --skip-ssl-validation \
        --username "${OPSMAN_USERNAME}" \
        --password "${OPSMAN_PASSWORD}" \
        upload-stemcell \
        --stemcell "${stemcell}"
  done
}

main "${PWD}"
