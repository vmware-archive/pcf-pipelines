#!/bin/bash

set -eu

curl \
  --silent \
  --insecure \
  --output fly \
  "${ATC_EXTERNAL_URL}/api/v1/cli?arch=amd64&platform=linux"

chmod +x fly

./fly --target self login \
  --insecure \
  --concourse-url "${ATC_EXTERNAL_URL}" \
  --username "${ATC_BASIC_AUTH_USERNAME}" \
  --password "${ATC_BASIC_AUTH_PASSWORD}" \
  --team-name "${ATC_TEAM_NAME}"

IFS=$'\n'
jobs=($JOBS)
for job in "${jobs[@]}"; do
  ./fly --target self trigger-job --watch --job $job
done
