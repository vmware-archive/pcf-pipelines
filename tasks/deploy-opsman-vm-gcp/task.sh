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

local cwd
cwd="${1}"

CMD_PATH="terraform/bin/terraform"

chmod +x iaas-util/cliaas-linux
AWS_UTIL_PATH="iaas-util/cliaas-linux"

OPSMAN_DISKIMAGE_NAME=$(grep ${OPSMAN_ZONE} pivnet-opsmgr/*GCP.yml | awk '{split($0, a); print a[2]}')
echo "deploying ami: ${OPSMAN_DISKIMAGE_NAME} into region ${OPSMAN_ZONE}"

IAAS_CONFIGURATION=$(cat <<-EOF
resource "google_compute_image" "bootable-opsman-image" {
  name       = "${OPSMAN_DISKIMAGE_NAME}-name"
  raw_disk {
    source = "https://storage.googleapis.com/${OPSMAN_DISKIMAGE_NAME}"
  }
}
resource "google_compute_subnetwork" "subnet-ops-manager" {
  name          = "${OPSMAN_SUBNET_NAME}"
  ip_cidr_range = "${OPSMAN_CIDR}"
  network       = "${OPSMAN_NET_NAME}"
}
resource "google_compute_instance" "ops-manager" {
  name         = "${OPSMAN_INSTANCE_NAME}"
  depends_on   = ["google_compute_subnetwork.subnet-ops-manager"]
  machine_type = "n1-standard-2"
  zone         = "${OPSMAN_ZONE}"

  tags = ["${OPSMAN_TAG}", "allow-https"]

  disk {
    image = "${OPSMAN_DISKIMAGE_NAME}-name"
    size  = 50
  }

  network_interface {
    subnetwork = "${OPSMAN_SUBNET_NAME}"

    access_config {
      nat_ip = "${OPSMAN_PUBLIC_IP}"
    }
  }
}
EOF
)
  echo $IAAS_CONFIGURATION > ./opsman_settings.tf

  read OLD_OPSMAN_INSTANCE ERR < <(./${AWS_UTIL_PATH} "${AWS_INSTANCE_NAME}")

  if [ -n "$OLD_OPSMAN_INSTANCE" ]
  then
    echo "Destroying old Ops Manager instance. ${OLD_OPSMAN_INSTANCE}"
    ./${CMD_PATH} import aws_instance.ops-manager-to-purge ${OLD_OPSMAN_INSTANCE}
    ./${CMD_PATH} destroy -state=./terraform.tfstate -target=aws_instance.ops-manager-to-purge -force
    rm ./terraform.tfstate
  fi

  echo "Provisioning Ops Manager"
  cat ./opsman_settings.tf
  ./${CMD_PATH} apply

# verify that ops manager started
  started=false
  timeout=$((SECONDS+${OPSMAN_TIMEOUT}))

  echo "Starting Ops manager on ${OPSMAN_URI}"

  timeout=$((SECONDS+${OPSMAN_TIMEOUT}))
  while [[ $started ]]; do
    HTTP_OUTPUT=$(curl --write-out %{http_code} --silent -k --output /dev/null ${OPSMAN_URI})
    if [[ $HTTP_OUTPUT == *"302"* || $HTTP_OUTPUT == *"301"* ]]; then
      echo "Site is started! $HTTP_OUTPUT"
      break
    else
      if [[ $SECONDS -gt $timeout ]]; then
        echo "Timed out waiting for ops manager site to start."
        exit 1
      fi
    fi
  done

}
main "${PWD}"
