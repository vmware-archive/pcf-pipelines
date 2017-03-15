#!/bin/bash -u

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
  chmod +x pcf-pipelines/cliaas-linux
  CLIAAS_PATH="pcf-pipelines/cliaas-linux"
  TMP_CREDFILE="/tmp/gcp-creds.json"
  CLIAAS_CONFIG="config.yml"
  OPSMAN_DISKIMAGE_NAME=$(grep ${OPSMAN_ZONE} pivnet-opsmgr/*GCP.yml | awk '{split($0, a); print a[2]}')

  echo "deploying vm w/ disk-image: ${OPSMAN_DISKIMAGE_NAME} into region ${OPSMAN_ZONE}"
  echo "${OPSMAN_GCP_CREDFILE_CONTENTS}" > ${TMP_CREDFILE}
cat > ${CLIAAS_CONFIG} <<EOF
gcp:
  credfile: ${TMP_CREDFILE} 
  project: ${OPSMAN_PROJECT} 
  zone: ${OPSMAN_ZONE} 
  disk_image_url: https://storage.googleapis.com/${OPSMAN_DISKIMAGE_NAME}
EOF

  echo "Provisioning New Ops Manager"
  ./${CLIAAS_PATH} -c ${CLIAAS_CONFIG} replace-vm -i ${OPSMAN_VM_IDENTIFIER}

  echo "cleanup"
  rm -f ${TMP_CREDFILE}
}
main
