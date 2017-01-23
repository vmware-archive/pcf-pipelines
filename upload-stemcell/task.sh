#!/bin/bash -eu

function main() {
  local cwd
  cwd="${1}"

  local stemcell
  stemcell="$(ls -1 "${cwd}"/stemcell/*.tgz)"

  chmod +x ./tool-om/om-linux

  ./tool-om/om-linux --target ${OPSMAN_URI} \
     --skip-ssl-validation \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
     upload-stemcell \
     --stemcell "${stemcell}"
}

main "${PWD}"
