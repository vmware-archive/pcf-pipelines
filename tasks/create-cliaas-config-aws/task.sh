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

ami=$(grep ${AWS_REGION} pivnet-opsmgr/*AWS.yml | cut -f2 -d':' | tr -d " ")

if [ -z "$ami" ]; then
  echo Could not find AMI for AWS region \"$AWS_REGION\". Available choices are:
  cat pivnet-opsmgr/*AWS.yml | cut -f1 -d':'
  exit 1
fi

cat > cliaas-config/config.yml <<EOF
aws:
  access_key_id: ${AWS_ACCESS_KEY_ID}
  secret_access_key: ${AWS_SECRET_ACCESS_KEY}
  region: ${AWS_REGION}
  vpc: ${AWS_VPC_ID}
  ami: ${ami}
EOF
