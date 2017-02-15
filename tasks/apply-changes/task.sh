#!/bin/bash -eu

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
