#!/bin/bash -e

#mv tool-om/om-linux-* tool-om/om-linux
chmod +x tool-om/om-linux
CMD=./tool-om/om-linux

RELEASE=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k available-products | grep p-redis`

PRODUCT_NAME=`echo $RELEASE | cut -d"|" -f2 | tr -d " "`
PRODUCT_VERSION=`echo $RELEASE | cut -d"|" -f3 | tr -d " "`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

OTHER_AZS=$(fn_other_azs $OTHER_JOB_AZS)

NETWORK=$(cat <<-EOF
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

PROPERTIES=$(cat <<-EOF
{
    ".properties.syslog_address": {
      "value": "$SYSLOG_HOST"
    },
    ".properties.syslog_port": {
      "value": $SYSLOG_PORT
    },
    ".properties.backups_selector": {
      "value": "SCP Backups"
    },
    ".properties.metrics_disable_etcd_tls": {
      "value": "$DISABLE_TLS"
    },
    ".properties.backups_selector.scp.server": {
      "value": "$BACKUPS_SCP_HOST"
    },
    ".properties.backups_selector.scp.user": {
      "value": "$BACKUPS_SCP_USER"
    },
    ".properties.backups_selector.scp.key": {
      "value": "$BACKUPS_SCP_KEY"
    },
    ".properties.backups_selector.scp.path": {
      "value": "$BACKUPS_SCP_DESTINATION"
    },
    ".properties.backups_selector.scp.port": {
      "value": $BACKUPS_SCP_PORT
    },
    ".properties.backups_selector.scp.cron_schedule": {
      "value": "$BACKUPS_CRON_SCHEDULE"
    },
    ".properties.backups_selector.scp.bg_save_timeout": {
      "value": $BACKUPS_SCP_TIMEOUT
    },
    ".properties.backups_selector.scp.fingerprint": {
      "value": null
    }
}
EOF
)

RESOURCES=$(cat <<-EOF
{
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$PROPERTIES" -pn "$NETWORK" -pr "$RESOURCES"
