#!/bin/bash -eu

function main() {
  echo "Applying changes on Ops manager @ ${OPSMAN_URI}"
  chmod +x tool-om/om-linux
  CMD_PATH="tool-om/om-linux"
  TIMEOUT=$((SECONDS+${OPSMAN_TIMEOUT}))
  set +e
  while [[ true ]]; do

    ./${CMD_PATH} --target "${OPSMAN_URI}" \
       --skip-ssl-validation \
       --username "${OPSMAN_USERNAME}" \
       --password "${OPSMAN_PASSWORD}" \
       apply-changes

    EXITCODE=$?

    if [[ ${EXITCODE} -ne 0 && ${SECONDS} -gt ${TIMEOUT} ]]; then
      echo "Timed out waiting for ops manager site to start."
      exit 1
    fi

    if [[ ${EXITCODE} -eq 0 ]]; then
      break
    fi
  done
  set -e
}

main "${PWD}"
