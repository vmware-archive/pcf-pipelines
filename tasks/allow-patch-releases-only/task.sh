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

echo "Checking if you are applying an allowed patch upgrade @ ${OPSMAN_URI}"
for i in `om-linux --target "https://${OPSMAN_URI}" --skip-ssl-validation --username "${OPSMAN_USERNAME}" --password "${OPSMAN_PASSWORD}" deployed-products | egrep -v "\-\-\-|NAME" | awk -F"|" '{ print $3 }'`; do
  echo $i | grep "${PRODUCT_VERSION_REGEX}";
  if [[ $? == 1 ]]; then
    echo "current version: ${i}"
    echo "attempting to upgrade to ${PRODUCT_VERSION_REGEX}"
    echo "Pivotal recommends that you only automate
    patch upgrades of PCF, and perform major or minor
    upgrades manually to ensure that no high-impact
    changes to the platform are introduced without
    your prior knowledge."
    exit 1
  fi
done
