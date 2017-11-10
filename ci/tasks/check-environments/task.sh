#!/bin/bash

set -eu

export INTERVAL=60

EXPECTED_RC_VERSION=$(jq -r .Release.Version pivnet-rc/metadata.json)

function curl_api() {
  local concourse_oauth_token=$1
  local api=$2
  curl -s -k \
    -H "cookie: ATC-Authorization=\"Bearer ${concourse_oauth_token}\"" \
    ${ATC_EXTERNAL_URL}${api} | jq .
}

function get_concourse_oauth_token() {
  curl -s -k \
    --user "${ATC_BASIC_AUTH_USERNAME}:${ATC_BASIC_AUTH_PASSWORD}" \
    "${ATC_EXTERNAL_URL}/api/v1/teams/${ATC_TEAM_NAME}/auth/token" | \
    jq -r .value
}

function dot_and_sleep() {
  echo -n "."
  sleep ${INTERVAL}
}

function main() {
  local concourse_token=$(get_concourse_oauth_token)

  for iteration in $(seq ${TIMEOUT_MINUTES}); do
    local JOB_JSON=$(curl_api ${concourse_token} /api/v1/teams/${ATC_TEAM_NAME}/pipelines/${PIPELINE}/jobs/${JOB})
    local CURRENT_BUILD_STATUS=$(echo ${JOB_JSON} | jq -r .next_build.status)
    if [ "${CURRENT_BUILD_STATUS}" != "null" ]; then
      dot_and_sleep
      continue
    fi

    local FINISHED_BUILD_API_URL=$(echo ${JOB_JSON} | jq -r .finished_build.api_url)
    if [ "${FINISHED_BUILD_API_URL}" == "null" ]; then
      dot_and_sleep
      continue
    fi

    local RESOURCES_JSON=$(curl_api "${concourse_token}" "${FINISHED_BUILD_API_URL}/resources")
    local JOB_STATUS=$(echo ${JOB_JSON} | \
      jq -r .finished_build.status)

    local RC_VERSION=$(echo ${RESOURCES_JSON} | \
    jq -r '.inputs[] | select(.name=="pcf-pipelines-tarball").metadata[] | select(.name=="version" ).value')
    echo "${PIPELINE}/${JOB}@${RC_VERSION} ${JOB_STATUS}"

    if [[ "${JOB_STATUS}" == "succeeded" ]]; then
      if [[ "${DISABLE_PIVNET_VERSION_CHECK}" == "true" ]]; then
        exit 0
      fi

      if [[ "${RC_VERSION}" == "${EXPECTED_RC_VERSION}" ]]; then
        exit 0
      fi
    fi

    exit 1
  done

  echo "Timeout waiting for completion of ${PIPELINE}/${JOB}"
  exit 1
}

main
