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

cat > cliaas-config/gcpcreds.json <<EOF
${GCP_SERVICE_ACCOUNT_KEY}
EOF

DISK_IMAGE_PATH=$(grep ${PIVNET_IMAGE_REGION} pivnet-opsmgr/*GCP.yml | awk '{split($0, a); print a[2]}')
if [ -z "DISK_IMAGE_PATH" ]; then
  echo Could not find disk image for region \"PIVNET_IMAGE_REGION\". Available choices are:
  cat pivnet-opsmgr/*GCP.yml | cut -f1 -d':'
  exit 1
fi

cat > cliaas-config/config.yml <<EOF
gcp:
  credfile: cliaas-config/gcpcreds.json
  zone: ${GCP_ZONE}
  project: ${GCP_PROJECT_ID}
  disk_image_url: ${DISK_IMAGE_PATH}
EOF
