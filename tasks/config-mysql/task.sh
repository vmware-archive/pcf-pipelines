#!/bin/bash -e


#mv tool-om/om-linux-* tool-om/om-linux
chmod +x tool-om/om-linux
CMD=./tool-om/om-linux

RELEASE=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k available-products | grep p-mysql`

PRODUCT_NAME=`echo $RELEASE | cut -d"|" -f2 | tr -d " "`
PRODUCT_VERSION=`echo $RELEASE | cut -d"|" -f3 | tr -d " "`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION


PRODUCT_PROPERTIES=$(cat <<-EOF
{
  ".properties.optional_protections": {
    "value": "enable"
  },
  ".properties.optional_protections.enable.recipient_email": {
    "value": "$PROTECTION_EMAIL"
  },
  ".properties.optional_protections.enable.prevent_auto_rejoin": {
    "value": true
  },
  ".properties.optional_protections.enable.replication_canary": {
    "value": true
  },
  ".properties.optional_protections.enable.notify_only": {
    "value": false
  },
  ".properties.optional_protections.enable.canary_poll_frequency": {
    "value": 30
  },
  ".properties.optional_protections.enable.canary_write_read_delay": {
    "value": 20
  },
  ".properties.server_activity_logging": {
    "value": "enable"
  },
  ".properties.server_activity_logging.enable.audit_logging_events": {
    "value": "connect,query"
  },
  ".properties.backup_options": {
    "value": "enable"
  },
  ".properties.backup_options.enable.cron_schedule": {
    "value": "$BACKUP_CRON_SCHEDULE"
  },
  ".properties.backup_options.enable.backup_all_masters": {
    "value": true
  },
  ".properties.backups": {
    "value": "scp"
  },
  ".properties.backups.scp.server": {
    "value": "$BACKUP_SCP_HOST"
  },
  ".properties.backups.scp.user": {
    "value": "$BACKUP_SCP_USER"
  },
  ".properties.backups.scp.destination": {
    "value": "$BACKUP_SCP_DESTINATION"
  },
  ".properties.backups.scp.scp_key": {
    "value": "$BACKUP_SCP_KEY"
  },
  ".properties.backups.scp.port": {
    "value": $BACKUP_SCP_PORT
  },
  ".proxy.static_ips": {
    "value": null
  },
  ".cf-mysql-broker.bind_hostname": {
    "value": null
  }
}

EOF
)

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

OTHER_AZS=$(fn_other_azs $DEPLOYMENT_NW_AZS)

PRODUCT_NETWORK_CONFIG=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$SINGLETON_JOB_AZ"
  },
  "other_availability_zones": [
    $OTHER_AZS
  ],
  "network": {
    "name": "$NETWORK_NAME"
  }
}
EOF
)

PRODUCT_RESOURCE_CONFIG=$(cat <<-EOF
{
  "mysql": {
    "instance_type": {"id": "automatic"},
    "instances" : $MYSQL_SERVER_INSTANCES
  },
  "backup-prepare": {
    "instance_type": {"id": "automatic"},
    "instances" : $BACKUP_PREPARE_INSTANCES
  },
  "proxy": {
    "instance_type": {"id": "automatic"},
    "instances" : $MYSQL_PROXY_INSTANCES
  },
  "monitoring": {
    "instance_type": {"id": "automatic"},
    "instances" : $MONITORING_INSTANCES
  },
  "cf-mysql-broker": {
    "instance_type": {"id": "automatic"},
    "instances" : $MYSQL_BROKER_INSTANCES
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$PRODUCT_PROPERTIES" -pn "$PRODUCT_NETWORK_CONFIG" -pr "$PRODUCT_RESOURCE_CONFIG"

if [[ "$BACKUP_ENABLE" == "disable" ]]; then
echo "Terminating SSL at the gorouters and using self signed/provided certs..."
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backup_options": {
    "value": "disable"
  }
}
EOF
)

elif [[ "$BACKUP_ENABLE" == "enable" ]]; then
echo "Terminating SSL at the gorouters and reusing self signed/provided certs from ERT tile..."
BACKUP_PROPERTIES=$(cat <<-EOF
{
  ".properties.backup_options": {
    "value": "enable"
  },
  ".properties.backup_options.enable.cron_schedule": {
    "value": "$CRON_SCHEDULE"
  },
  ".properties.backup_options.enable.backup_all_masters": {
    "value": $BACKUP_ALL_NODES
  }
}
EOF
)
fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$BACKUP_PROPERTIES"

if [[ "$BACKUP_DESTINATION" == "none" ]]; then
echo "None backup destination..."
BACKUP_DESTINATION_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "disable"
  }
}
EOF
)

elif [[ "$BACKUP_DESTINATION" == "s3" ]]; then
echo "Using s3 as the backup destination..."
SSL_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "enable"
  },
  ".properties.backups.enable.endpoint_url": {
    "value": "$S3_ENDPOINT"
  },
  ".properties.backups.enable.bucket_name": {
    "value": "$S3_BUCKET_NAME"
  },
  ".properties.backups.enable.bucket_path": {
    "value": "$S3_BUCKET_PATH"
  },
  ".properties.backups.enable.access_key_id": {
    "value": "$S3_ACCESS_KEY_ID"
  },
  ".properties.backups.enable.secret_access_key": {
    "value": {
      "secret": "$S3_SECRET_KEY"
    }
  }
}
EOF
)

elif [[ "$BACKUP_DESTINATION" == "scp" ]]; then
echo "Using scp as the backup destination..."
BACKUP_DESTINATION_PROPERTIES=$(cat <<-EOF
{
  ".properties.backups": {
    "value": "scp"
  },
  ".properties.backups.scp.user": {
    "value": "$SCP_USER"
  },
  ".properties.backups.scp.server": {
    "value": "$SCP_SERVER"
  },
  ".properties.backups.scp.destination": {
    "value": "$SCP_DESTINATION_DIR"
  },
  ".properties.backups.scp.scp_key": {
    "value": "$SCP_PRIVATE_KEY"
  },
  ".properties.backups.scp.port": {
    "value": $SCP_PORT
  }
}
EOF
)

fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$BACKUP_DESTINATION_PROPERTIES"
