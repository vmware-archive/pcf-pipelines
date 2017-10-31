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

files=$(aws --endpoint-url $S3_ENDPOINT --region $S3_REGION s3 ls "${S3_BUCKET_TERRAFORM}/")

set +e
echo $files | grep terraform.tfstate
if [ "$?" -gt "0" ]; then
  echo "{\"version\": 3}" > terraform.tfstate
  aws s3 --endpoint-url $S3_ENDPOINT --region $S3_REGION cp terraform.tfstate "s3://${S3_BUCKET_TERRAFORM}/terraform.tfstate"
  set +x
  if [ "$?" -gt "0" ]; then
    echo "Failed to upload empty tfstate file"
    exit 1
  fi
else
  echo "terraform.tfstate file found, skipping"
  exit 0
fi
