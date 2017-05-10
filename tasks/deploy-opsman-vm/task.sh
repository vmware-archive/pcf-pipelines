#!/bin/bash -eu

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

  gunzip ./govc/govc_linux_amd64.gz
  chmod +x ./govc/govc_linux_amd64

  CMD_PATH="govc/govc_linux_amd64"

  local cwd
  cwd="${1}"

  export CURR_DIR=$(pwd)
  export OPSMGR_VERSION=$(cat ./pivnet-opsmgr/metadata.json | jq '.Release.Version' | sed -e 's/^"//' -e 's/"$//')
  export OPSMAN_NAME=OpsManager-${OPSMGR_VERSION}-$(date +"%Y%m%d%H%S")
  export OPSMAN_PATH=`ls $CURR_DIR/pivnet-opsmgr/*.{yml,yaml,ova} $CURR_DIR/pivnet-opsmgr/*_image 2>/dev/null | grep -v metadata.yaml`


IAAS_CONFIGURATION=$(cat <<-EOF
{
  "DiskProvisioning":"thin",
  "IPAllocationPolicy":"dhcpPolicy",
  "IPProtocol":"IPv4",
  "Name": "$OPSMAN_NAME",
  "NetworkMapping": [{
    "Name":"Network 1",
    "Network":"$OPSMAN_NETWORK"
  }],
  "PropertyMapping":[
    {"Key":"ip0","Value":"$OPSMAN_IP"},
    {"Key":"netmask0","Value":"$NETMASK"},
    {"Key":"gateway","Value":"$GATEWAY"},
    {"Key":"DNS","Value":"$DNS"},
    {"Key":"ntp_servers","Value":"$NTP"},
    {"Key":"admin_password","Value":"$OPSMAN_ADMIN_PASSWORD"}
  ],
  "PowerOn":false,
  "InjectOvfEnv":false,
  "WaitForIP":false
}
EOF
)
  echo $IAAS_CONFIGURATION > ./opsman_settings.json

  cat ./opsman_settings.json

  echo "Importing OVA of new OpsMgr VM..."
  echo "Running govc import.ova -options=opsman_settings.json -k=true ${OPSMAN_PATH}"
  ./${CMD_PATH} import.ova -options=opsman_settings.json -k=true ${OPSMAN_PATH}
  #
  # echo "Setting CPUs on new OpsMgr VM... /${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER}/${OPSMAN_NAME}"
  ./${CMD_PATH} vm.change -c=2 -k=true -vm=${OPSMAN_NAME}
  #
  # echo "Shutting down OLD OpsMgr VM... ${OPSMAN_IP}"
  ./${CMD_PATH} vm.power -off=true -k=true -vm.ip=${OPSMAN_IP}
  #
  # echo "Starting OpsMgr VM... /${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER}/${OPSMAN_NAME}"
  ./${CMD_PATH} vm.power -k=true -on=true ${OPSMAN_NAME}

  # make sure that vm and ops manager app is up
  started=false
  timeout=$((SECONDS+${OPSMAN_TIMEOUT}))
  set +e
  while ! $started; do
      OUTPUT=$(./${CMD_PATH} vm.info -vm.ip=${OPSMAN_IP} -k=true 2>&1)

      if [[ $SECONDS -gt $timeout ]]; then
        echo "Timed out waiting for VM to start."
        exit 1
      fi

      if [[ $OUTPUT == *"no such VM"* ]]; then
        echo "...VM is not running! $OUTPUT"
      else
        echo "...VM is running! $OUTPUT"
        timeout=$((SECONDS+${OPSMAN_TIMEOUT}))
        while [[ $started ]]; do
          HTTP_OUTPUT=$(curl --write-out %{http_code} --silent --output /dev/null ${OPSMAN_IP})
          if [[ $HTTP_OUTPUT == *"302"* || $HTTP_OUTPUT == *"301"* ]]; then
            echo "Site is started! $OUTPUT >>> $HTTP_OUTPUT"
            exit 0
          else
            if [[ $SECONDS -gt $timeout ]]; then
              echo "Timed out waiting for ops manager site to start."
              exit 1
            fi
          fi
        done
        break
      fi
  done
  set -e
}

echo "Running deploy of OpsMgr VM task..."
main "${PWD}"
