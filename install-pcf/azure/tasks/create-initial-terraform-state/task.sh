#!/bin/bash

set -ex

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

blobs=$(az storage blob list -c ${CONTAINER})
files=$(echo "$blobs" | jq -r .[].name)

set +e
echo ${files} | grep terraform.tfstate
if [ "$?" -gt "0" ]; then
  echo "{\"version\": 3}" > terraform.tfstate
  az storage blob upload -c ${CONTAINER} -n terraform.tfstate -f terraform.tfstate
  set +x
  if [ "$?" -gt "0" ]; then
    echo "Failed to upload empty tfstate file"
    exit 1
  fi
  set -x
  az storage blob snapshot -c ${CONTAINER} -n terraform.tfstate
  set +x
  if [ "$?" -gt "0" ]; then
    echo "Failed to create snapshot of tfstate file"
    exit 1
  fi
else
  echo "terraform.tfstate file found, skipping"
  exit 0
fi
