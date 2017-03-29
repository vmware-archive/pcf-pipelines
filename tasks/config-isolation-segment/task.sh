#!/bin/bash -e

chmod +x tool-om/om-linux
CMD_PATH="./tool-om/om-linux"

function fn_ert_balanced_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

ERT_AZS=$(fn_ert_balanced_azs $TILE_OTHER_AVAILABILITY_ZONES)

TILE_NETWORK=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$TILE_SINGLETON_AVAILABILITY_ZONE"
  },
  "other_availability_zones": [
    $ERT_AZS
  ],
  "network": {
    "name": "$TILE_NETWORK"
  }
}
EOF
)

TILE_PROPERTIES=$(cat <<-EOF
{
  ".isolated_diego_cell.executor_disk_capacity": {
    "value": $CELL_EXECUTOR_DISK_CAPACITY
  },
  ".isolated_diego_cell.executor_memory_capacity": {
    "value": $CELL_EXECUTOR_MEMORY_CAPACITY
  },
  ".isolated_diego_cell.garden_network_mtu": {
    "value": $CELL_GARDEN_NETWORK_MTU
  },
  ".isolated_diego_cell.garden_network_pool": {
    "value": "$CELL_GARDEN_NETWORK_POOL"
  },
  ".isolated_diego_cell.insecure_docker_registry_list": {
    "value": "$CELL_INSECURE_DOCKER_REGISTRY_LIST"
  },
  ".isolated_diego_cell.placement_tag": {
    "value": "$CELL_PLACEMENT_TAG"
  },
  ".isolated_router.static_ips": {
    "value": $ISOLATED_ROUTER_STATIC_IPS
  },
  ".properties.networking_point_of_entry": {
    "value": "$NETWORKING_POINT_OF_ENTRY"
  },
  ".properties.networking_point_of_entry.terminate_at_router.ssl_ciphers": {
    "value": "$TERMINATE_AT_ROUTER_SSL_CIPHERS"
  },
  ".properties.networking_point_of_entry.terminate_at_router.ssl_rsa_certificate": {
    "value": {
      "cert_pem": "$TERMINATE_AT_ROUTER_SSL_RSA_CERTIFICATE",
      "private_key_pem": "$TERMINATE_AT_ROUTER_SSL_RSA_KEY"
    }
  }
}
EOF
)

TILE_RESOURCES=$(cat <<-EOF
{
  "isolated_router": {
    "instance_type": {"id": "automatic"},
    "instances" : $ISOLATED_ROUTER_COUNT
  },
  "isolated_diego_cell": {
    "instance_type": {"id": "automatic"},
    "instances" : $ISOLATED_DIEGO_CELL_COUNT
  }
}
EOF
)

#	--product-properties "$TILE_PROPERTIES" \
echo $TILE_NETWORK
echo $TILE_PROPERTIES
echo $TILE_RESOURCES

$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-network "$TILE_NETWORK" \
	--product-resources "$TILE_RESOURCES"
