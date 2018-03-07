#!/usr/bin/env bash

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

set -eu

function getDiskSize() {
  if [[ "${VM_DISK_SIZE_GB}" == "" || "${VM_DISK_SIZE_GB}" == "null" ]]; then
    VM_DISK_SIZE_GB="$( cliaas-linux get-vm-disk-size -c cliaas-config/config.yml -i $VM_IDENTIFIER )"
  fi

  echo "${VM_DISK_SIZE_GB}"
}

diskSizeGB="$( getDiskSize )"

cliaas-linux replace-vm \
  --config cliaas-config/config.yml \
  --identifier "${VM_IDENTIFIER}" \
  --disk-size-gb "${diskSizeGB}"
