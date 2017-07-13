#!/bin/bash

echo "$OPENSTACK_CA_CERT" > /ca.crt
export OS_CACERT='/ca.crt'

OPSMAN_FILE=$(find ops-manager/ -name '*.raw')
if [ -z $OPSMAN_FILE ]; then
  echo "FATAL: We didn't get an opsman image from Pivnet."
  exit 1
fi

VERSION=$(echo $OPSMAN_FILE | perl -lane "print \$1 if (/pcf-openstack-(.*?).raw/)")
IMG_NAME="$OPSMAN_IMAGE-$VERSION"

echo "Looking for $IMG_NAME in glance."
openstack image list | grep -q $IMG_NAME
if [ $? != 0 ]; then
  echo "$IMG_NAME is not available in glance."
  exit 1
fi

echo "Booting OpsMan: $OPSMAN_VM_NAME"
openstack server create \
  --image $IMG_NAME \
  --flavor $OPSMAN_FLAVOR \
  --key-name $OPSMAN_KEY \
  --security-group $SECURITY_GROUP \
  --nic net-id=$INFRA_NETWORK \
  $OPSMAN_VM_NAME

if [ $? == 0 ]; then
  echo "Sleeping 20 seconds for the VM to boot before adding a floating IP."
  sleep 20 # Give openstack a few moments to get the VM organized.
  echo "Adding floating IP: $OPSMAN_FLOATING_IP to $OPSMAN_VM_NAME"
  openstack server add floating ip $OPSMAN_VM_NAME $OPSMAN_FLOATING_IP

  echo "Opsman URL: http://$OPSMAN_FLOATING_IP/"
else
  echo "Failed to boot $OPSMAN_VM_NAME"
  openstack server show $OPSMAN_VM_NAME
fi
