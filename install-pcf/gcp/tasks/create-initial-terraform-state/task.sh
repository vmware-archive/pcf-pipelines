#!/bin/bash

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

echo $GCP_SERVICE_ACCOUNT_KEY > gcloud.key
gcloud auth activate-service-account --key-file=gcloud.key

files=$(gsutil ls "gs://${TERRAFORM_STATEFILE_BUCKET}")

if [ $(echo $files | grep -c terraform.tfstate) == 0 ]; then
  echo "{\"version\": 3}" > terraform.tfstate
  gsutil cp terraform.tfstate "gs://${TERRAFORM_STATEFILE_BUCKET}/terraform.tfstate"
else
  echo "terraform.tfstate file found, skipping"
  exit 0
fi
