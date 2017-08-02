#!/bin/bash

set -eu

IFS=$'\n'
for line in $PIPELINE_PARAMS; do
  echo "$line" >> params.yml
done

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

./fly --target self set-pipeline \
  --non-interactive \
  --pipeline "${PIPELINE_NAME}" \
  --config "${PIPELINE_PATH}" \
  --load-vars-from params.yml
