#!/bin/bash

echo "$OPENSTACK_CA_CERT" > /ca.crt
export OS_CACERT='/ca.crt'

OPSMAN_FILE=$(find ops-manager/ -name '*.raw')
if [ -z $OPSMAN_FILE ]; then
  echo "FATAL: We didn't get an opsman image from Pivnet."
  exit 1
fi

VERSION=$(jq -r .Release.Version ops-manager/metadata.json)
IMG_NAME="$OPSMAN_IMAGE-$VERSION"

echo "Looking for $IMG_NAME in glance."
openstack image list | grep -q $IMG_NAME
if [ $? == 0 ]; then
  echo "$IMG_NAME is already installed."
  exit 0
fi

echo "Installing: $IMG_NAME"
openstack image create \
  --disk-format qcow2 \
  --container-format bare \
  --private \
  --file $OPSMAN_FILE \
  $IMG_NAME
