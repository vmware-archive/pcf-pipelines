#!/bin/bash

function delete_admin_router() {
   echo "Deleting router $ADMIN_ROUTER: "
   neutron router-gateway-clear $ADMIN_ROUTER
   neutron router-interface-delete $ADMIN_ROUTER ${INFRA_NETWORK}-subnet
   neutron router-interface-delete $ADMIN_ROUTER ${ERT_NETWORK}-subnet
   neutron router-interface-delete $ADMIN_ROUTER ${SERVICES_NETWORK}-subnet
   neutron router-interface-delete $ADMIN_ROUTER ${DYNAMIC_SERVICES_NETWORK}-subnet
   openstack router delete $ADMIN_ROUTER
}

function delete_networks() {
  for net in $INFRA_NETWORK $DMZ_NETWORK $ERT_NETWORK $SERVICES_NETWORK $DYNAMIC_SERVICES_NETWORK
  do
    echo "Deleting network $net: "
    neutron net-delete $net
  done
}

function delete_secgroup() {
  echo "Deleting security group $SECURITY_GROUP: "
  openstack security group delete $SECURITY_GROUP
}

function remove_opsman_floating_ip() {
  echo "Removing floating IP ($OPSMAN_FLOATING_IP) from $OPSMAN_VM_NAME: "
  openstack server remove floating ip $OPSMAN_VM_NAME $OPSMAN_FLOATING_IP
}

function delete_opsman() {
  echo "Deleting $OPSMAN_VM_NAME vm: "
  openstack server delete $OPSMAN_VM_NAME
}

function delete_opsman_installation() {
  echo "Deleting PCF installation..."
  om-linux \
    --target "https://${OPSMAN_URI}" \
    --skip-ssl-validation \
    --username $OPSMAN_USERNAME \
    --password $OPSMAN_PASSWORD \
    delete-installation
}

delete_opsman_installation
remove_opsman_floating_ip
delete_opsman
delete_admin_router
delete_networks
delete_secgroup
