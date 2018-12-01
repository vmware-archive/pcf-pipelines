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

function main() {
  local cwd
  cwd="${1}"

  printf "Waiting for %s to come up" "$OPSMAN_DOMAIN_OR_IP_ADDRESS"
  until $(curl --output /dev/null --silent --head --fail -k https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}); do
    printf '.'
    sleep 5
  done
  printf '\n'

  om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
      --skip-ssl-validation \
      --request-timeout 86400 \
      --decryption-passphrase "${OPSMAN_PASSPHRASE}" \
      import-installation \
      --installation "${cwd}/opsmgr-settings/${OPSMAN_SETTINGS_FILENAME}"
 }

 main "${PWD}"
