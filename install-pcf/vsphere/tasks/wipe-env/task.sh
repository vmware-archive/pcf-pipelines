#!/bin/bash
set -eu

root=$(pwd)

source "${root}/pcf-pipelines/functions/check_opsman_available.sh"

opsman_available=$(check_opsman_available $OPSMAN_DOMAIN_OR_IP_ADDRESS)
if [[ $opsman_available == "available" ]]; then
  om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username $OPSMAN_USERNAME \
    --password $OPSMAN_PASSWORD \
    delete-installation
fi

if [ -z "$GOVC_RESOURCE_POOL" ]; then
  echo "GOVC_RESOURCE_POOL must not be empty!"
  exit 1
fi

# Power-off and remove any outstanding vms from the slot
for OUTSTANDING_VM in $(govc find -k $GOVC_RESOURCE_POOL -type m); do
  echo "Powering off and removing $OUTSTANDING_VM"
  set +e
  govc vm.power -k -vm.ipath=$OUTSTANDING_VM -off
  set -e
  govc vm.unregister -k -vm.ipath=$OUTSTANDING_VM
done
