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

echo "Configuring ${PRODUCT_NAME} network"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-network "$TILE_NETWORK"

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

echo "Configuring ${PRODUCT_NAME} resources"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-resources "$TILE_RESOURCES"

TILE_PROPERTIES=$(cat <<-EOF
{
  ".isolated_diego_cell.executor_disk_capacity": {
    "value": ${CELL_EXECUTOR_DISK_CAPACITY:-null}
  },
  ".isolated_diego_cell.executor_memory_capacity": {
    "value": ${CELL_EXECUTOR_MEMORY_CAPACITY:-null}
  },
  ".isolated_diego_cell.garden_network_mtu": {
    "value": ${CELL_GARDEN_NETWORK_MTU:-null}
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
    "value": ${ISOLATED_ROUTER_STATIC_IPS:-null}
  }
}
EOF
)

echo "Configuring ${PRODUCT_NAME} properties"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-properties "$TILE_PROPERTIES"

if [ "$ISOLATED_ROUTER_COUNT" -gt "0" ]; then
if [[ "$NETWORKING_POINT_OF_ENTRY" == "terminate_at_router" ]]; then
  if [[ -z "$TERMINATE_AT_ROUTER_SSL_RSA_CERTIFICATE" ]]; then
    DOMAINS=$(cat <<-EOF
{"domains": ["*.$SYSTEM_DOMAIN", "*.$APPS_DOMAIN", "*.login.$SYSTEM_DOMAIN", "*.uaa.$SYSTEM_DOMAIN"] }
EOF
    )

    CERTIFICATES=`$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
      curl -p "$OPS_MGR_GENERATE_SSL_ENDPOINT" -x POST -d "$DOMAINS"`

    export SSL_CERT=`echo $CERTIFICATES | jq '.certificate' | tr -d '"'`
    export SSL_PRIVATE_KEY=`echo $CERTIFICATES | jq '.key' | tr -d '"'`

    echo "Using self signed certificates generated using Ops Manager..."

  else
    SSL_CERT=$TERMINATE_AT_ROUTER_SSL_RSA_CERTIFICATE
    SSL_PRIVATE_KEY=$TERMINATE_AT_ROUTER_SSL_RSA_KEY
  fi

echo "Forward SSL to Isolation Segment Router"
CF_SSL_TERM_PROPERTIES=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "terminate_at_router"
  },
  ".properties.networking_point_of_entry.terminate_at_router.ssl_ciphers": {
    "value": "$TERMINATE_AT_ROUTER_SSL_CIPHERS"
  },
  ".properties.networking_point_of_entry.haproxy.ssl_rsa_certificate": {
    "value": {
      "cert_pem": "$SSL_CERT",
      "private_key_pem": "$SSL_PRIVATE_KEY"
    }
  }
}
EOF
)

elif [[ "$NETWORKING_POINT_OF_ENTRY" == "terminate_at_router_ert_cert" ]]; then
echo "Forward SSL to Isolation Segment Router with ERT Router certificates"

CF_SSL_TERM_PROPERTIES=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "terminate_at_router_ert_cert"
  }
}
EOF
)

elif [[ "$NETWORKING_POINT_OF_ENTRY" == "terminate_before_router" ]]; then
echo "Forward unencrypted traffic to Elastic Runtime Router"
CF_SSL_TERM_PROPERTIES=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "terminate_before_router"
  }
}
EOF
)

fi
else
echo "No routers configured, but need to change SSL termination to option that has no required fields"
CF_SSL_TERM_PROPERTIES=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "terminate_before_router"
  }
}
EOF
)
fi

echo "Configuring ${PRODUCT_NAME} SSL"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-properties "$CF_SSL_TERM_PROPERTIES"
