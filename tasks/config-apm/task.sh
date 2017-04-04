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
  ".push-apps.elasticsearch_logqueue_instance_count": {
    "value": ${ELASTICSEARCH_LOGQUEUE_INSTANCE_COUNT:-1}
  },
  ".elasticsearch_master.heap_size": {
    "value": "$ELASTICSEARCH_MASTER_HEAP_SIZE"
  },
  ".push-apps.ingestor_instance_count": {
    "value": ${INGESTOR_INSTANCE_COUNT:-1}
  },
  ".mysql.innodb_buffer_size": {
    "value": "$MYSQL_INNODB_BUFFER_SIZE"
  },
  ".push-apps.mysql_logqueue_instance_count": {
    "value": ${MYSQL_LOGQUEUE_INSTANCE_COUNT:-1}
  },
  ".mysql_monitor.notifications_email": {
    "value": "$MYSQL_MONITOR_NOTIFICATIONS_EMAIL"
  }
}
EOF
)

TILE_RESOURCES=$(cat <<-EOF
{
  "elasticsearch_data": {
    "instance_type": {"id": "automatic"},
    "instances" : $ELASTICSEARCH_DATA_COUNT
  },
  "proxy": {
    "instance_type": {"id": "automatic"},
    "instances" : $MYSQL_PROXY_COUNT
  },
  "mysql": {
    "instance_type": {"id": "automatic"},
    "instances" : $MYSQL_SERVER_COUNT
  }
}
EOF
)

$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-properties "$TILE_PROPERTIES" \
	--product-network "$TILE_NETWORK" \
	--product-resources "$TILE_RESOURCES"
