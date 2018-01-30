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

  local cwd=$PWD
  local download_dir="${cwd}/stemcells"
  local diag_report="${cwd}/diagnostic-report/exported-diagnostic-report.json"

  cp ${cwd}/pivnet-stemcells/* ${download_dir}

  # get the deduplicated stemcell filename for each deployed release (skipping p-bosh)
  local bosh_io_stemcells=($( (jq --raw-output '.added_products.deployed[] | select (.name | contains("p-bosh") | not) | select (.stemcell | contains("ubuntu") | not) |.stemcell' | \
    sort -u) < "$diag_report"))
  if [ ${#bosh_io_stemcells[@]} -eq 0 ]; then
    echo "No installed products found that require a ubuntu stemcell"
    exit 0
  fi

  mkdir -p "${download_dir}"

  # extract the stemcell version from the filename, e.g. 3312.21, and download the file from pivnet
  for stemcell in "${bosh_io_stemcells[@]}"; do

    local version=$(echo "$stemcell" | grep -Eo "[0-9]+\.[0-9]+")
    local stemcell_type=bosh-$(ruby -e "puts '$stemcell'.split('$version-')[1].split('.')[0]")

    curl -L -J -o ${download_dir}/${stemcell} https://bosh.io/d/stemcells/${stemcell_type}?v=${version}
  done
}

function abort() {
  echo "$1"
  exit 1
}

main
