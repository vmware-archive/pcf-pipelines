#!/bin/bash -eu

function main() {
  export CURR_DIR=$(pwd)
  export OPSMGR_VERSION=$(cat ./pivnet-opsmgr/metadata.json | jq '.Release.Version' | sed -e 's/^"//' -e 's/"$//')

  export OPSMAN_NAME=OpsManager-${OPSMGR_VERSION}-$(date +"%Y%m%d%H%S")

  echo '
  {
    "DiskProvisioning":"thin",
    "IPAllocationPolicy":"dhcpPolicy",
    "IPProtocol":"IPv4",
    "NetworkMapping": [{
      "Name":"VM Network",
      "Network":"${OPSMAN_NETWORK}"
    }],
    "PropertyMapping":[
      {"Key":"ip0","Value":"${OPSMAN_IP}"},
      {"Key":"netmask0","Value":"${NETMASK}"},
      {"Key":"gateway","Value":"${GATEWAY}"},
      {"Key":"DNS","Value":"${DNS}"},
      {"Key":"ntp_servers","Value":"${NTP}"},
      {"Key":"admin_password","Value":"${OPSMAN_ADMIN_PASSWORD}"}
    ],
    "PowerOn":false,
    "InjectOvfEnv":false,
    "WaitForIP":false
  }' > ./opsman_settings.json

  cat ./opsman_settings.json

  echo "Importing OVA of new OpsMgr VM..."
  echo "Running govc import.ova -options=opsman_settings.json -name=${OPSMAN_NAME} -k=true -u=${GOVC_URL} -ds=${GOVC_DATASTORE} -dc=${GOVC_DATACENTER} -pool=${GOVC_RESOURCE_POOL} -folder=/${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER} ${CURR_DIR}/pivnet-opsmgr/pcf-vsphere-1.9.2.ova"
  govc import.ova -options=opsman_settings.json -name=${OPSMAN_NAME} -k=true -u=${GOVC_URL} -ds=${GOVC_DATASTORE} -dc=${GOVC_DATACENTER} -pool=${GOVC_RESOURCE_POOL} -folder=/${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER} ${CURR_DIR}/pivnet-opsmgr/pcf-vsphere-1.9.2.ova

  echo "Setting CPUs on new OpsMgr VM... /${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER}/${OPSMAN_NAME}"
  govc vm.change -c=2 -k=true -vm /${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER}/${OPSMAN_NAME}

  echo "Shutting down OLD OpsMgr VM... ${OPSMAN_IP}"
  govc vm.power -off=true -k=true -vm.ip=${OPSMAN_IP}

  echo "Starting OpsMgr VM... /${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER}/${OPSMAN_NAME}"
  govc vm.power -k=true -on=true /${GOVC_DATACENTER}/${OPSMAN_VM_FOLDER}/${OPSMAN_NAME}

}

echo "Running deploy of OpsMgr VM task..."
main "${PWD}"
