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


TILE_PROPERTIES=$(cat <<-EOF
{
  ".properties.metrics_disable_etcd_tls": {
    "value": ${METRICS_DISABLE_ETCD_TLS:-true}
  },
  ".properties.metrics_polling_interval": {
    "value": ${METRICS_POLLING_INTERVAL:-30}
  },
  ".cf-redis-broker.redis_maxmemory": {
    "value": "${REDIS_MAXMEMORY:-512MB}"
  },
  ".cf-redis-broker.service_instance_limit": {
    "value": ${SERVICE_INSTANCE_LIMIT:-5}
  },
  ".properties.syslog_address": {
    "value": "$SYSLOG_ADDRESS"
  },
  ".properties.syslog_port": {
    "value": ${SYSLOG_PORT:-null}
  },
  ".properties.syslog_transport": {
    "value": "${SYSLOG_TRANSPORT:-TCP}"
  }
}
EOF
)

echo "Configuring ${PRODUCT_NAME} properties"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-properties "$TILE_PROPERTIES"


if [ "$BACKUPS_SELECTOR" == "No Backups" ]; then
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups_selector": {
    "value": "$BACKUPS_SELECTOR"
  }
}
EOF
)
elif [ "$BACKUPS_SELECTOR" == "Azure Backups" ]; then
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups_selector": {
    "value": "$BACKUPS_SELECTOR"
  },
  ".properties.backups_selector.azure.account": {
    "value": "$BACKUPS_SELECTOR_AZURE_ACCOUNT"
  },
  ".properties.backups_selector.azure.bg_save_timeout": {
    "value": ${BACKUPS_SELECTOR_AZURE_BG_SAVE_TIMEOUT:-10}
  },
  ".properties.backups_selector.azure.blob_store_base_url": {
    "value": "$BACKUPS_SELECTOR_AZURE_BLOB_STORE_BASE_URL"
  },
  ".properties.backups_selector.azure.container": {
    "value": "$BACKUPS_SELECTOR_AZURE_CONTAINER"
  },
  ".properties.backups_selector.azure.cron_schedule": {
    "value": "${BACKUPS_SELECTOR_AZURE_CRON_SCHEDULE:-0 0 * * *}"
  },
  ".properties.backups_selector.azure.path": {
    "value": "$BACKUPS_SELECTOR_AZURE_PATH"
  },
  ".properties.backups_selector.azure.storage_access_key": {
    "value": "$BACKUPS_SELECTOR_AZURE_STORAGE_ACCESS_KEY"
  }
}
EOF
)
elif [ "$BACKUPS_SELECTOR" == "Google Cloud Storage Backups" ]; then
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups_selector": {
    "value": "$BACKUPS_SELECTOR"
  },
  ".properties.backups_selector.gcs.bg_save_timeout": {
    "value": ${BACKUPS_SELECTOR_GCS_BG_SAVE_TIMEOUT:-10}
  },
  ".properties.backups_selector.gcs.bucket_name": {
    "value": "$BACKUPS_SELECTOR_GCS_BUCKET_NAME"
  },
  ".properties.backups_selector.gcs.cron_schedule": {
    "value": "${BACKUPS_SELECTOR_GCS_CRON_SCHEDULE:-0 0 * * *}"
  },
  ".properties.backups_selector.gcs.project_id": {
    "value": "$BACKUPS_SELECTOR_GCS_PROJECT_ID"
  },
  ".properties.backups_selector.gcs.service_account_json": {
    "value": "$BACKUPS_SELECTOR_GCS_SERVICE_ACCOUNT_JSON"
  }
}
EOF
)
elif [ "$BACKUPS_SELECTOR" == "S3 Backups" ]; then
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups_selector": {
    "value": "$BACKUPS_SELECTOR"
  },
  ".properties.backups_selector.s3.access_key_id": {
    "value": "$BACKUPS_SELECTOR_S3_ACCESS_KEY_ID"
  },
  ".properties.backups_selector.s3.bg_save_timeout": {
    "value": ${BACKUPS_SELECTOR_S3_BG_SAVE_TIMEOUT:-10}
  },
  ".properties.backups_selector.s3.bucket_name": {
    "value": "$BACKUPS_SELECTOR_S3_BUCKET_NAME"
  },
  ".properties.backups_selector.s3.cron_schedule": {
    "value": "${BACKUPS_SELECTOR_S3_CRON_SCHEDULE:-0 0 * * *}"
  },
  ".properties.backups_selector.s3.endpoint_url": {
    "value": "$BACKUPS_SELECTOR_S3_ENDPOINT_URL"
  },
  ".properties.backups_selector.s3.path": {
    "value": "$BACKUPS_SELECTOR_S3_PATH"
  },
  ".properties.backups_selector.s3.secret_access_key": {
    "value": "$BACKUPS_SELECTOR_S3_SECRET_ACCESS_KEY"
  }
}
EOF
)
elif [ "$BACKUPS_SELECTOR" == "SCP Backups" ]; then
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups_selector": {
    "value": "$BACKUPS_SELECTOR"
  },
  ".properties.backups_selector.scp.bg_save_timeout": {
    "value": ${BACKUPS_SELECTOR_SCP_BG_SAVE_TIMEOUT:-10}
  },
  ".properties.backups_selector.scp.cron_schedule": {
    "value": "${BACKUPS_SELECTOR_SCP_CRON_SCHEDULE:-0 0 * * *}"
  },
  ".properties.backups_selector.scp.fingerprint": {
    "value": "$BACKUPS_SELECTOR_SCP_FINGERPRINT"
  },
  ".properties.backups_selector.scp.key": {
    "value": "$BACKUPS_SELECTOR_SCP_KEY"
  },
  ".properties.backups_selector.scp.path": {
    "value": "$BACKUPS_SELECTOR_SCP_PATH"
  },
  ".properties.backups_selector.scp.port": {
    "value": ${BACKUPS_SELECTOR_SCP_PORT:-22}
  },
  ".properties.backups_selector.scp.server": {
    "value": "$BACKUPS_SELECTOR_SCP_SERVER"
  },
  ".properties.backups_selector.scp.user": {
    "value": "$BACKUPS_SELECTOR_SCP_USER"
  }
}
EOF
)
fi

echo "Configuring ${PRODUCT_NAME} ${BACKUPS_SELECTOR}"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-properties "$BACKUP_PROPERTIES"


TILE_RESOURCES=$(cat <<-EOF
{
  "dedicated-node": {
    "instance_type": {"id": "automatic"},
    "instances" : $DEDICATED_NODE_COUNT
  }
}
EOF
)

echo "Configuring ${PRODUCT_NAME} resources"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-resources "$TILE_RESOURCES"
