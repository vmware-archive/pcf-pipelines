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

VHD_IMAGE_URL=$(grep ${AZURE_REGION} pivnet-opsmgr/*Azure.yml | awk '{split($0, a); print a[2]}')

cat > cliaas-config/config.yml <<EOF
azure:
  vhd_image_url: ${VHD_IMAGE_URL}
  subscription_id: ${AZURE_SUBSCRIPTION_ID}
  client_id: ${AZURE_CLIENT_ID}
  client_secret: ${AZURE_CLIENT_SECRET}
  tenant_id: ${AZURE_TENANT_ID}
  resource_group_name: ${AZURE_RESOURCE_GROUP_NAME}
  storage_account_name: ${AZURE_STORAGE_ACCOUNT_NAME}
  storage_account_key: ${AZURE_STORAGE_ACCOUNT_KEY}
  storage_container_name: ${AZURE_STORAGE_CONTAINER_NAME}
EOF
