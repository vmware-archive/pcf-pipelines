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
  cliaas_path="pcf-pipelines/cliaas-linux"

  chmod +x $cliaas_path

  tmp_credfile="/tmp/gcp-creds.json"
  cliaas_config="config.yml"
  opsman_diskimage_name=$(grep ${OPSMAN_ZONE} pivnet-opsmgr/*GCP.yml | awk '{split($0, a); print a[2]}')

  echo "deploying vm w/ disk-image: ${opsman_diskimage_name} into region ${OPSMAN_ZONE}"
  echo "${OPSMAN_GCP_CREDFILE_CONTENTS}" > ${tmp_credfile}

  cat > ${cliaas_config} <<EOF
gcp:
  credfile: ${tmp_credfile}
  project: ${OPSMAN_PROJECT} 
  zone: ${OPSMAN_ZONE} 
  disk_image_url: https://storage.googleapis.com/${opsman_diskimage_name}
EOF

  echo "Provisioning New Ops Manager"
  ./${cliaas_path} -c ${cliaas_config} replace-vm -i ${OPSMAN_VM_IDENTIFIER}

  echo "cleanup"
  rm -f ${tmp_credfile}
}
main
