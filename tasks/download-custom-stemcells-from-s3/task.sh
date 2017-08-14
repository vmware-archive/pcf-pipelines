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
  if [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then abort "The required env var AWS_ACCESS_KEY_ID was not set"; fi
  if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]; then abort "The required env var AWS_SECRET_ACCESS_KEY was not set"; fi
  if [[ -z "${S3_BUCKET_NAME}" ]]; then abort "The required env var S3_BUCKET_NAME was not set"; fi
  if [[ -z "${S3_ENDPOINT}" ]]; then
    S3_ENDPOINT=https://s3.amazonaws.com
  fi

  local cwd="${PWD}"
  local download_dir="${cwd}/stemcells"
  local diag_report="${cwd}/diagnostic-report/exported-diagnostic-report.json"

  # get the deduplicated stemcell filename for each deployed release (skipping p-bosh)
  local stemcells=($( (jq --raw-output '.added_products.deployed[] | select (.name | contains("p-bosh") | not) | .stemcell' | sort -u) < "${diag_report}"))
  if [ "${#stemcells[@]}" -eq 0 ]; then
    echo "No installed products found that require a stemcell"
    exit 0
  fi

  # extract the stemcell version from the filename, e.g. 3312.21, and download the file from s3
  echo "Using s3 endpoint: ${S3_ENDPOINT}"
  for stemcell in "${stemcells[@]}"; do
    if [[ -z $(aws s3 --endpoint-url ${S3_ENDPOINT} ls "s3://${S3_BUCKET_NAME}/${stemcell}") ]]; then
      abort "Could not find ${stemcell} in s3://${S3_BUCKET_NAME}."
    fi
    aws s3 --endpoint-url ${S3_ENDPOINT} cp "s3://${S3_BUCKET_NAME}/${stemcell}" "${download_dir}/${stemcell}"
  done
}

function abort() {
  echo "${1}"
  exit 1
}

main
