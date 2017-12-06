#!/bin/bash

set -eu

# Copyright 2017-Present Pivotal Software, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function check_for_no_pending_changes() {
  local pending_changes_count=$(om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --client-id "${OPSMAN_CLIENT_ID}" \
    --client-secret "${OPSMAN_CLIENT_SECRET}" \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    curl -path /api/v0/staged/pending_changes | jq ".product_changes | length")
  if [[ $pending_changes_count -ne 0 ]]; then
    echo "Detected $pending_changes_count pending changes. Aborting."
    exit 1
  fi
}

function dump_installations() {
  om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --client-id "${OPSMAN_CLIENT_ID}" \
    --client-secret "${OPSMAN_CLIENT_SECRET}" \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    curl -path /api/v0/installations | jq -S .
}

function main() {

  local cwd
  cwd="${1}"

  check_for_no_pending_changes

  dump_installations > installations-before.json

  om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
     --skip-ssl-validation \
     --client-id "${OPSMAN_CLIENT_ID}" \
     --client-secret "${OPSMAN_CLIENT_SECRET}" \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
     --request-timeout 6000 \
     export-installation \
     --output-file "${cwd}/opsmgr-settings/${OPSMAN_SETTINGS_FILENAME}"

  dump_installations > installations-after.json

  if [[ "$(cat installations-after.json)" != "$(cat installations-before.json)" ]]; then
    echo "Detected changes in the installation log (change log)."
    exit 1
  fi

  check_for_no_pending_changes
}

main "${PWD}"
