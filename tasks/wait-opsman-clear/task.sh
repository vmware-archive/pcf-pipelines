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

#This script polls ops mgr waiting for pending changes and running installs to be empty before beginning
#POLL_INTERVAL controls how quickly the script will poll ops mgr for changes to pending changes/running installs

POLL_INTERVAL=30
function main() {

  local cwd
  cwd="${1}"

  set +e
  while :
  do

      om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
           --skip-ssl-validation \
           --client-id "${OPSMAN_CLIENT_ID}" \
           --client-secret "${OPSMAN_CLIENT_SECRET}" \
           --username "${OPSMAN_USERNAME}" \
           --password "${OPSMAN_PASSWORD}" \
            curl -path /api/v0/staged/pending_changes > changes-status.txt

      if [[ $? -ne 0 ]]; then
        echo "Could not login to ops man"
        cat changes-status.txt
        exit 1
      fi

      om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
           --skip-ssl-validation \
           --client-id "${OPSMAN_CLIENT_ID}" \
           --client-secret "${OPSMAN_CLIENT_SECRET}" \
           --username "${OPSMAN_USERNAME}" \
           --password "${OPSMAN_PASSWORD}" \
           curl -path /api/v0/installations > running-status.txt

      if [[ $? -ne 0 ]]; then
        echo "Could not login to ops man"
        cat running-status.txt
        exit 1
      fi

      ACTION_STATUS=$(jq -r '[ .product_changes[] | select(.action != "unchanged") ] | length' changes-status.txt)
      jq -e -r '.installations[0] | select(.status=="running")' running-status.txt >/dev/null
      RUNNING_STATUS=$?

      if [[ ${ACTION_STATUS} -eq 0 && ${RUNNING_STATUS} -ne 0 ]]; then
          echo "No pending changes or running installs detected. Proceeding"
          exit 0
      fi
      echo "Pending changes or running installs detected. Waiting"
      sleep $POLL_INTERVAL
  done
  set -e
}

main "${PWD}"
