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
  ".cf-mysql-broker.bind_hostname": {
    "value": "$CF_MYSQL_BROKER_BIND_HOSTNAME"
  },
  ".cf-mysql-broker.quota_enforcer_pause": {
    "value": ${CF_MYSQL_BROKER_QUOTA_ENFORCER_PAUSE:-30}
  },
  ".mysql.mysql_start_timeout": {
    "value": ${MYSQL_MYSQL_START_TIMEOUT:-60}
  },
  ".mysql.roadmin_password": {
    "value": {
      "secret": "$MYSQL_ROADMIN_PASSWORD"
    }
  },
  ".mysql.skip_name_resolve": {
    "value": ${MYSQL_SKIP_NAME_RESOLVE:-true}
  },
  ".mysql.wsrep_debug": {
    "value": ${MYSQL_WSREP_DEBUG:-true}
  },
  ".properties.optional_protections": {
    "value": "${OPTIONAL_PROTECTIONS:-enable}"
  },
  ".properties.optional_protections.enable.canary_poll_frequency": {
    "value": ${OPTIONAL_PROTECTIONS_CANARY_POLL_FREQUENCY:-30}
  },
  ".properties.optional_protections.enable.canary_write_read_delay": {
    "value": ${OPTIONAL_PROTECTIONS_CANARY_WRITE_READ_DELAY:-20}
  },
  ".properties.optional_protections.enable.notify_only": {
    "value": ${OPTIONAL_PROTECTIONS_NOTIFY_ONLY:-false}
  },
  ".properties.optional_protections.enable.prevent_auto_rejoin": {
    "value": ${OPTIONAL_PROTECTIONS_PREVENT_AUTO_REJOIN:-true}
  },
  ".properties.optional_protections.enable.recipient_email": {
    "value": "$OPTIONAL_PROTECTIONS_RECIPIENT_EMAIL"
  },
  ".properties.optional_protections.enable.replication_canary": {
    "value": ${OPTIONAL_PROTECTIONS_REPLICATION_CANARY:-true}
  },
  ".properties.server_activity_logging": {
    "value": "${SERVER_ACTIVITY_LOGGING:-enable}"
  },
  ".properties.server_activity_logging.enable.audit_logging_events": {
    "value": "${SERVER_ACTIVITY_LOGGING_ENABLE_AUDIT_LOGGING_EVENTS:-connect,query}"
  },
  ".proxy.shutdown_delay": {
    "value": ${PROXY_SHUTDOWN_DELAY:-0}
  },
  ".proxy.startup_delay": {
    "value": ${PROXY_STARTUP_DELAY:-0}
  },
  ".proxy.static_ips": {
    "value": ${PROXY_STATIC_IPS:-null}
  }
}
EOF
)

#   ".properties.plan_collection": {
#     "value": [
#       {
#         "name": {
#           "value": "${PLAN_1_NAME:-100mb}"
#         },
#         "description": {
#           "value": "${PLAN_1_DESCRIPTION:-100MB default}"
#         },
#         "max_storage_mb": {
#           "value": ${PLAN_1_MAX_STORAGE_MB:-100}
#         },
#         "max_user_connections": {
#           "value": ${PLAN_1_MAX_USER_CONNECTIONS:-40}
#         },
#         "private": {
#           "value": ${PLAN_1_PRIVATE:-false}
#         }
#       }
#     ]
#   },

echo "Configuring ${PRODUCT_NAME} properties"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-properties "$TILE_PROPERTIES"


if [ "$BACKUPS_SELECTOR" == "No Backups" ]; then
BACKUP_PREPARE_COUNT=0
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "$BACKUPS_SELECTOR"
  },
  ".properties.backup_options": {
    "value": "disable"
  }
}
EOF
)
elif [ "$BACKUPS_SELECTOR" == "Ceph or Amazon S3" ]; then
BACKUP_PREPARE_COUNT=1
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "enable"
  },
  ".properties.backup_options": {
    "value": "enable"
  },
  ".properties.backup_options.enable.backup_all_masters": {
    "value": ${BACKUP_OPTIONS_ENABLE_BACKUP_ALL_MASTERS:-true}
  },
 ".properties.backup_options.enable.cron_schedule": {
    "value": "${BACKUP_OPTIONS_ENABLE_CRON_SCHEDULE:-0 0 * * *}"
  },
  ".properties.backups.enable.access_key_id": {
    "value": "$BACKUPS_SELECTOR_S3_ACCESS_KEY_ID"
  },
  ".properties.backups.enable.bucket_name": {
    "value": "$BACKUPS_SELECTOR_S3_BUCKET_NAME"
  },
  ".properties.backups.enable.endpoint_url": {
    "value": "$BACKUPS_SELECTOR_S3_ENDPOINT_URL"
  },
  ".properties.backups.enable.bucket_path": {
    "value": "$BACKUPS_SELECTOR_S3_PATH"
  },
  ".properties.backups.enable.secret_access_key": {
    "value": {
      "secret": "$BACKUPS_SELECTOR_S3_SECRET_ACCESS_KEY"
    }
  }
}
EOF
)
elif [ "$BACKUPS_SELECTOR" == "SCP to a Remote Host" ]; then
BACKUP_PREPARE_COUNT=1
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "scp"
  },
  ".properties.backup_options": {
    "value": "enable"
  },
  ".properties.backup_options.enable.backup_all_masters": {
    "value": ${BACKUP_OPTIONS_ENABLE_BACKUP_ALL_MASTERS:-true}
  },
 ".properties.backup_options.enable.cron_schedule": {
    "value": "${BACKUP_OPTIONS_ENABLE_CRON_SCHEDULE:-0 0 * * *}"
  },
  ".properties.backups_selector.scp.fingerprint": {
    "value": "$BACKUPS_SELECTOR_SCP_FINGERPRINT"
  },
  ".properties.backups.scp.scp_key": {
    "value": "$BACKUPS_SELECTOR_SCP_KEY"
  },
  ".properties.backups.scp.destination": {
    "value": "$BACKUPS_SELECTOR_SCP_PATH"
  },
  ".properties.backups.scp.port": {
    "value": ${BACKUPS_SELECTOR_SCP_PORT:-22}
  },
  ".properties.backups.scp.server": {
    "value": "$BACKUPS_SELECTOR_SCP_SERVER"
  },
  ".properties.backups.scp.user": {
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
  "backup-prepare": {
    "instance_type": {"id": "automatic"},
    "instances" : $BACKUP_PREPARE_COUNT
  },
  "cf-mysql-broker": {
    "instance_type": {"id": "automatic"},
    "instances" : ${CF_MYSQL_BROKER_COUNT:-2}
  },
  "monitoring": {
    "instance_type": {"id": "automatic"},
    "instances" : ${MONITORING_COUNT:-1}
  },
  "mysql": {
    "instance_type": {"id": "automatic"},
    "instances" : ${MYSQL_COUNT:-3}
  },
  "proxy": {
    "instance_type": {"id": "automatic"},
    "instances" : ${PROXY_COUNT:-2}
  }
}
EOF
)

echo "Configuring ${PRODUCT_NAME} resources"
$CMD_PATH --target $OPSMAN_URI --username $OPSMAN_USERNAME --password $OPSMAN_PASSWORD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-resources "$TILE_RESOURCES"
