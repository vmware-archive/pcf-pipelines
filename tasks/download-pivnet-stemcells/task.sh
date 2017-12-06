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
  if [ -z "$API_TOKEN" ]; then abort "The required env var API_TOKEN was not set for pivnet"; fi
  if [ -z "$IAAS_TYPE" ]; then abort "The required env var IAAS_TYPE was not set"; fi

  local cwd=$PWD
  local download_dir="${cwd}/stemcells"
  local diag_report="${cwd}/diagnostic-report/exported-diagnostic-report.json"

  pivnet-cli login --api-token="$API_TOKEN"
  pivnet-cli eula --eula-slug=pivotal_software_eula >/dev/null

  # get the deduplicated stemcell filename for each deployed release (skipping p-bosh)
  local ubuntu_stemcells=($( (jq --raw-output '.added_products.deployed[] | select (.name | contains("p-bosh") | not) | select (.stemcell | contains("ubuntu")) |.stemcell' | \
    sort -u) < "$diag_report"))
  if [ ${#ubuntu_stemcells[@]} -eq 0 ]; then
    echo "No installed products found that require a ubuntu stemcell"
    exit 0
  fi

  mkdir -p "$download_dir"

  # extract the stemcell version from the filename, e.g. 3312.21, and download the file from pivnet
  for stemcell in "${ubuntu_stemcells[@]}"; do
    local stemcell_version
    stemcell_version=$(echo "$stemcell" | grep -Eo "[0-9]+(\.[0-9]+)?")
    download_stemcell_version $stemcell_version
  done
}

function abort() {
  echo "$1"
  exit 1
}

function download_stemcell_version() {
  local stemcell_version
  stemcell_version="$1"

  # ensure the stemcell version found in the manifest exists on pivnet
  if [[ $(pivnet-cli pfs -p stemcells -r "$stemcell_version") == *"release not found"* ]]; then
    abort "Could not find the required stemcell version ${stemcell_version}. This version might not be published on PivNet yet, try again later."
  fi

  # loop over all the stemcells for the specified version and then download it if it's for the IaaS we're targeting
  for product_file_id in $(pivnet-cli pfs -p stemcells -r "$stemcell_version" --format json | jq .[].id); do
    local product_file_name
    product_file_name=$(pivnet-cli product-file -p stemcells -r "$stemcell_version" -i "$product_file_id" --format=json | jq .name)
    if echo "$product_file_name" | grep -iq "$IAAS_TYPE"; then
      pivnet-cli download-product-files -p stemcells -r "$stemcell_version" -i "$product_file_id" -d "$download_dir" --accept-eula
      return 0
    fi
  done

  # shouldn't get here
  abort "Could not find stemcell ${stemcell_version} for ${IAAS_TYPE}. Did you specify a supported IaaS type for this stemcell version?"
}

main
