#!/bin/bash

echo "$OPENSTACK_CA_CERT" > /ca.crt
export OS_CACERT='/ca.crt'

function create_private_network() {
  local NETNAME=$1
  local SUBNET=$2
  local DNS=$3

  echo -n "Creating Network $NETNAME ($SUBNET): "
  openstack network create $NETNAME
  if [ -n "$DNS" ]; then
    openstack subnet create ${NETNAME}-subnet --dns-nameserver $DNS --network $NETNAME --subnet-range $SUBNET
  else
    openstack subnet create ${NETNAME}-subnet --network $NETNAME --subnet-range $SUBNET
  fi
}

function create_admin_router() {
  local ROUTER=$1
  echo -n "Creating router $ROUTER: "

  openstack router create $ROUTER
  neutron router-gateway-set $ROUTER $EXTERNAL_NETWORK
  openstack router add subnet $ROUTER ${INFRA_NETWORK}-subnet
  openstack router add subnet $ROUTER ${ERT_NETWORK}-subnet
  openstack router add subnet $ROUTER ${SERVICES_NETWORK}-subnet
  openstack router add subnet $ROUTER ${DYNAMIC_SERVICES_NETWORK}-subnet
}

function create_secgroup() {
   local SECURITY_GROUP=$1

   openstack security group list | grep -w " $SECURITY_GROUP "
   if [ $? != 0 ]; then
     echo -n "Creating CF security group: "

     openstack security group create $SECURITY_GROUP

     echo -"Adding rules to security group CF"
     # TCP
     for port in 22 80 443 4443; do
       echo -n " - adding tcp $port: "
         neutron security-group-rule-create --direction ingress \
           --ethertype IPv4 --protocol tcp --port-range-min $port \
           --port-range-max $port $SECURITY_GROUP
     done
     echo -n " - adding icmp: "
     neutron security-group-rule-create --protocol icmp \
       --direction ingress --remote-ip-prefix 0.0.0.0/0 $SECURITY_GROUP
     for port in 68 3457; do
       echo -n " - adding udp $port: "
         neutron security-group-rule-create --direction ingress \
           --ethertype IPv4 --protocol udp --port-range-min $port \
           --port-range-max $port $SECURITY_GROUP
     done
    echo -n " - adding udp 1-65535 for $SECURITY_GROUP :"
    neutron security-group-rule-create --direction ingress \
      --ethertype IPv4 --protocol udp --port-range-min 1 \
      --port-range-max 65535 --remote-group-id $SECURITY_GROUP \
      $SECURITY_GROUP
    echo -n " - adding tcp 1-65535 for $SECURITY_GROUP :"
    neutron security-group-rule-create --direction ingress \
      --ethertype IPv4 --protocol tcp --port-range-min 1 \
      --port-range-max 65535 --remote-group-id $SECURITY_GROUP \
      $SECURITY_GROUP
  else
     echo "Ok"
   fi
}

create_private_network $INFRA_NETWORK $INFRA_SUBNET $INFRA_DNS
create_private_network $ERT_NETWORK $ERT_SUBNET
create_private_network $SERVICES_NETWORK $SERVICES_SUBNET
create_private_network $DYNAMIC_SERVICES_NETWORK $DYNAMIC_SERVICES_SUBNET
create_admin_router $ADMIN_ROUTER
create_secgroup $SECURITY_GROUP
