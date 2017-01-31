#!/bin/bash -eu

function main() {
  export CURR_DIR=$(pwd)
  export OPSMGR_VERSION=$(cat ./pivnet-opsmgr/metadata.json | jq '.Release.Version' | sed -e 's/^"//' -e 's/"$//')
  export OPSMAN_NAME=OpsManager-${OPSMGR_VERSION}-$(date +"%Y%m%d%H%S")

IAAS_CONFIGURATION=$(cat <<-EOF
{
  "DiskProvisioning":"thin",
  "IPAllocationPolicy":"dhcpPolicy",
  "IPProtocol":"IPv4",
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
  echo "Running govc import.ova -options=opsman_settings.json -name=${OPSMAN_NAME} -k=true -u=${GOVC_URL} -ds=${GOVC_DATASTORE} -dc=${GOVC_DATACENTER} -pool=${GOVC_RESOURCE_POOL} -folder=/${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER} ${CURR_DIR}/pivnet-opsmgr/pcf-vsphere-1.9.2.ova"
  # govc import.ova -options=opsman_settings.json -name=${OPSMAN_NAME} -k=true -u=${GOVC_URL} -ds=${GOVC_DATASTORE} -dc=${GOVC_DATACENTER} -pool=${GOVC_RESOURCE_POOL} -folder=/${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER} ${CURR_DIR}/pivnet-opsmgr/pcf-vsphere-1.9.2.ova

  echo "Setting CPUs on new OpsMgr VM... /${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER}/${OPSMAN_NAME}"
  # govc vm.change -c=2 -k=true -vm /${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER}/${OPSMAN_NAME}

  echo "Shutting down OLD OpsMgr VM... ${OPSMAN_IP}"
  # govc vm.power -off=true -k=true -vm.ip=${OPSMAN_IP}

  echo "Starting OpsMgr VM... /${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER}/${OPSMAN_NAME}"
  # govc vm.power -k=true -on=true /${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER}/${OPSMAN_NAME}

  govc vm.info -vm.ip=${OPSMAN_IP} -k=true

  # make sure that vm and ops manager app is up
  started=false
  echo "...1"
  timeout=$((SECONDS+${OPSMAN_TIMEOUT}))
  echo "...2"
  while ! $started; do
    echo "...3"

      OUTPUT=$(govc vm.info -vm.ip=${OPSMAN_IP} -k=true 2>&1)
      echo "...4"

      if [[ $SECONDS -gt $timeout ]]; then
        echo "Timed out waiting for VM to start."
        exit 1
      fi
      echo "...5"

      if [[ $OUTPUT == *"no such VM"* ]]; then
        echo "...6"
        echo "...VM is not running! $OUTPUT"
      else
        echo "...VM is running! $OUTPUT"
        timeout=$((SECONDS+${OPSMAN_TIMEOUT}))
        while [[ $started ]]; do
          echo "...7"
          HTTP_OUTPUT=$(curl --write-out %{http_code} --silent --output /dev/null ${OPSMAN_IP})
          echo "...8"
          if [[ $HTTP_OUTPUT == *"302"* || $HTTP_OUTPUT == *"301"* ]]; then
            echo "Site is started! $OUTPUT >>> $HTTP_OUTPUT"
            break
          else
            if [[ $SECONDS -gt $timeout ]]; then
              echo "Timed out waiting for ops manager site to start."
              exit 1
            fi
          fi
        done
        echo "...9"
        break
      fi
  done

}

echo "Running deploy of OpsMgr VM task..."
main "${PWD}"
