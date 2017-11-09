#!/bin/bash

set -eu

export INTERVAL=60

function download_fly() {
    curl \
      --silent \
      --insecure \
      --output fly \
      "${ATC_EXTERNAL_URL}/api/v1/cli?arch=amd64&platform=linux"

    chmod +x fly
}

function dot_and_sleep() {
  echo -n "."
  sleep ${INTERVAL}
}

function main() {
  download_fly

  ./fly --target self login \
    --insecure \
    --concourse-url "${ATC_EXTERNAL_URL}" \
    --username "${ATC_BASIC_AUTH_USERNAME}" \
    --password "${ATC_BASIC_AUTH_PASSWORD}" \
    --team-name "${ATC_TEAM_NAME}"

  for iteration in $(seq ${TIMEOUT_MINUTES}); do
    if [[ -n $(./fly --target self ps | cut -d" " -f1 | grep "^${PIPELINE_NAME}$") ]]; then
      echo ""
      echo "${PIPELINE_NAME} exists."
      exit 0
    fi

    dot_and_sleep
  done

  echo ""
  echo "${PIPELINE_NAME} not found."
}

main
