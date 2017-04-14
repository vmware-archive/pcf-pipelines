#!/bin/bash -e

chmod +x tool-om/om-linux
CMD_PATH="./tool-om/om-linux"

function fn_ert_balanced_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

function fn_json_string_array {
  local cslist=$1
  echo $cslist | awk -F "[ \t]*,[ \t]*" -v bracketopen='[' -v bracketclose=']' -v quote='"'  -v OFS='","' '$1=$1 {print bracketopen quote $0 quote bracketclose}'
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

if [ "$RMQ_SERVER_ENABLE_TLS_1" == true ]; then
TLS1=$(cat <<-EOF
    [
      "enable_tls1_0"
    ]
EOF
)
fi

PLUGINS=$(fn_json_string_array "$RMQ_SERVER_PLUGINS")

TILE_PROPERTIES=$(cat <<-EOF
{
  ".properties.metrics_polling_interval": {
    "value": ${METRICS_POLLING_INTERVAL:-30}
  },
  ".properties.metrics_tls_disabled": {
    "value": ${METRICS_TLS_DISABLED:-true}
  },
  ".properties.syslog_address": {
    "value": "$SYSLOG_ADDRESS"
  },
  ".properties.syslog_port": {
    "value": ${SYSLOG_PORT:-null}
  },
  ".rabbitmq-broker.dns_host": {
    "value": "$RMQ_BROKER_DNS_HOST"
  },
  ".rabbitmq-broker.operator_set_policy_enabled": {
    "value": ${RMQ_BROKER_OPERATOR_SET_POLICY_ENABLED:-false}
  },
  ".rabbitmq-broker.policy_definition": {
    "value": "${RMQ_BROKER_POLICY_DEFINITION:-{\"ha-mode\": \"exactly\", \"ha-params\": 2, \"ha-sync-mode\": \"automatic\"}\n"
  },
  ".rabbitmq-haproxy.ports": {
    "value": "${RMQ_SERVER_PORTS:-15672, 5672, 5671, 1883, 8883, 61613, 61614, 15674}"
  },
  ".rabbitmq-haproxy.static_ips": {
    "value": ${RMQ_HAPROXY_STATIC_IPS:-null}
  },
  ".rabbitmq-server.cluster_partition_handling": {
    "value": "${RMQ_SERVER_CLUSTER_PARTITION_HANDLING:-pause_minority}"
  },
  ".rabbitmq-server.config": {
    "value": "$RMQ_SERVER_CONFIG"
  },
  ".rabbitmq-server.cookie": {
    "value": "$RMQ_SERVER_COOKIE"
  },
  ".rabbitmq-server.plugins": {
    "value": $PLUGINS
  },
  ".rabbitmq-server.security_options": {
    "value": ${TLS1:-null}
  },
  ".rabbitmq-server.server_admin_credentials": {
    "value": {
      "identity": "$RMQ_SERVER_SERVER_ADMIN_CREDENTIALS_USER",
      "password": "$RMQ_SERVER_SERVER_ADMIN_CREDENTIALS_PASSWORD"
    }
  },
  ".rabbitmq-server.static_ips": {
    "value": ${RMQ_SERVER_STATIC_IPS:-null}
  }
}
EOF
)

echo "Configuring ${PRODUCT_NAME} properties"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-properties "$TILE_PROPERTIES"


if [[ -z "$RMQ_SERVER_RSA_CERTIFICATE" ]]; then
  DOMAINS=$(cat <<-EOF
{"domains": ["*.$RMQ_DOMAIN"] }
EOF
  )

  CERTIFICATES=`$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
    curl -p "$OPSMAN_GENERATE_SSL_ENDPOINT" -x POST -d "$DOMAINS"`

  export SSL_CERT=`echo $CERTIFICATES | jq '.certificate' | tr -d '"'`
  export SSL_PRIVATE_KEY=`echo $CERTIFICATES | jq '.key' | tr -d '"'`

  echo "Using self signed certificates generated using Ops Manager..."

else
  SSL_CERT=$RMQ_SERVER_RSA_CERTIFICATE
  SSL_PRIVATE_KEY=$RMQ_SERVER_RSA_PRIVATE_KEY
fi

TILE_SSL_PROPERTIES=$(cat <<-EOF
{
  ".rabbitmq-server.rsa_certificate": {
    "value": {
      "cert_pem": "$SSL_CERT",
      "private_key_pem": "$SSL_PRIVATE_KEY"
    }
  },
  ".rabbitmq-server.ssl_cacert": {
    "value": "$RMQ_SERVER_SSL_CACERT"
  },
  ".rabbitmq-server.ssl_fail_if_no_peer_cert": {
    "value": ${RMQ_SERVER_SSL_FAIL_IF_NO_PEER_CERT:-false}
  },
  ".rabbitmq-server.ssl_verification_depth": {
    "value": ${RMQ_SERVER_SSL_VERIFICATION_DEPTH:-5}
  },
  ".rabbitmq-server.ssl_verify": {
    "value": ${RMQ_SERVER_SSL_VERIFY:-false}
  }
}
EOF
)

echo "Configuring ${PRODUCT_NAME} SSL properties"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-properties "$TILE_SSL_PROPERTIES"


TILE_RESOURCES=$(cat <<-EOF
{
  "rabbitmq-broker": {
    "instance_type": {"id": "automatic"},
    "instances" : ${RABBITMQ_BROKER_COUNT:-1}
  },
  "rabbitmq-haproxy": {
    "instance_type": {"id": "automatic"},
    "instances" : ${RABBITMQ_HAPROXY_COUNT:-1}
  },
  "rabbitmq-server": {
    "instance_type": {"id": "automatic"},
    "instances" : ${RABBITMQ_SERVER_COUNT:-3}
  }
}
EOF
)

echo "Configuring ${PRODUCT_NAME} resources"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-resources "$TILE_RESOURCES"
