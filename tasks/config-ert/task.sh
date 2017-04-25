#!/bin/bash -e

chmod +x tool-om/om-linux

CMD=./tool-om/om-linux

CF_RELEASE=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k available-products | grep cf`

PRODUCT_NAME=`echo $CF_RELEASE | cut -d"|" -f2 | tr -d " "`
PRODUCT_VERSION=`echo $CF_RELEASE | cut -d"|" -f3 | tr -d " "`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION

function fn_ert_balanced_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

ERT_AZS=$(fn_ert_balanced_azs $DEPLOYMENT_NW_AZS)

CF_NETWORK=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$ERT_SINGLETON_JOB_AZ"
  },
  "other_availability_zones": [
    $ERT_AZS
  ],
  "network": {
    "name": "$NETWORK_NAME"
  }
}
EOF
)

if [[ -z "$SSL_CERT" ]]; then
DOMAINS=$(cat <<-EOF
  {"domains": ["*.$SYSTEM_DOMAIN", "*.$APPS_DOMAIN", "*.login.$SYSTEM_DOMAIN", "*.uaa.$SYSTEM_DOMAIN"] }
EOF
)

  CERTIFICATES=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k curl -p "$OPS_MGR_GENERATE_SSL_ENDPOINT" -x POST -d "$DOMAINS"`

  export SSL_CERT=`echo $CERTIFICATES | jq '.certificate' | tr -d '"'`
  export SSL_PRIVATE_KEY=`echo $CERTIFICATES | jq '.key' | tr -d '"'`

  echo "Using self signed certificates generated using Ops Manager..."

fi


CF_PROPERTIES=$(cat <<-EOF
{
  ".properties.logger_endpoint_port": {
    "value": "$LOGGREGATOR_ENDPOINT_PORT"
  },
  ".properties.tcp_routing": {
    "value": "$TCP_ROUTING"
  },
  ".properties.tcp_routing.enable.reservable_ports": {
    "value": "$TCP_ROUTING_PORTS"
  },
  ".properties.route_services": {
    "value": "$ROUTE_SERVICES"
  },
  ".properties.route_services.enable.ignore_ssl_cert_verification": {
    "value": $IGNORE_SSL_CERT
  },
  ".properties.security_acknowledgement": {
    "value": "$SECURITY_ACKNOWLEDGEMENT"
  },
  ".properties.system_blobstore": {
    "value": "internal"
  },
  ".properties.mysql_backups": {
    "value": "$MYSQL_BACKUPS"
  },
  ".cloud_controller.system_domain": {
    "value": "$SYSTEM_DOMAIN"
  },
  ".cloud_controller.apps_domain": {
    "value": "$APPS_DOMAIN"
  },
  ".cloud_controller.default_quota_memory_limit_mb": {
    "value": $DEFAULT_QUOTA_MEMORY_LIMIT_IN_MB
  },
  ".cloud_controller.default_quota_max_number_services": {
    "value": $DEFAULT_QUOTA_MAX_SERVICES_COUNT
  },
  ".cloud_controller.allow_app_ssh_access": {
    "value": $ALLOW_APP_SSH_ACCESS
  },
  ".ha_proxy.static_ips": {
    "value": "$HA_PROXY_IPS"
  },
  ".ha_proxy.skip_cert_verify": {
    "value": $SKIP_CERT_VERIFY
  },
  ".router.static_ips": {
    "value": "$ROUTER_STATIC_IPS"
  },
  ".router.disable_insecure_cookies": {
    "value": $DISABLE_INSECURE_COOKIES
  },
  ".router.request_timeout_in_seconds": {
    "value": $ROUTER_REQUEST_TIMEOUT_IN_SEC
  },
  ".mysql_monitor.recipient_email": {
    "value": "$MYSQL_MONITOR_EMAIL"
  },
  ".diego_cell.garden_network_pool": {
    "value": "$GARDEN_NETWORK_POOL_CIDR"
  },
  ".diego_cell.garden_network_mtu": {
    "value": $GARDEN_NETWORK_MTU
  },
  ".tcp_router.static_ips": {
    "value": "$TCP_ROUTER_STATIC_IPS"
  },
  ".push-apps-manager.company_name": {
    "value": "$COMPANY_NAME"
  },
  ".diego_brain.static_ips": {
    "value": "$SSH_STATIC_IPS"
  }
}
EOF
)

CF_RESOURCES=$(cat <<-EOF
{
  "consul_server": {
    "instance_type": {"id": "automatic"},
    "instances" : $CONSUL_SERVER_INSTANCES
  },
  "nats": {
    "instance_type": {"id": "automatic"},
    "instances" : $NATS_INSTANCES
  },
  "etcd_tls_server": {
    "instance_type": {"id": "automatic"},
    "instances" : $ETCD_TLS_SERVER_INSTANCES
  },
  "nfs_server": {
    "instance_type": {"id": "automatic"},
    "instances" : $NFS_SERVER_INSTANCES
  },
  "mysql_proxy": {
    "instance_type": {"id": "automatic"},
    "instances" : $MYSQL_PROXY_INSTANCES
  },
  "mysql": {
    "instance_type": {"id": "automatic"},
    "instances" : $MYSQL_INSTANCES
  },
  "backup-prepare": {
    "instance_type": {"id": "automatic"},
    "instances" : $BACKUP_PREPARE_INSTANCES
  },
  "ccdb": {
    "instance_type": {"id": "automatic"},
    "instances" : $CCDB_INSTANCES
  },
  "uaadb": {
    "instance_type": {"id": "automatic"},
    "instances" : $UAADB_INSTANCES
  },
  "uaa": {
    "instance_type": {"id": "automatic"},
    "instances" : $UAA_INSTANCES
  },
  "cloud_controller": {
    "instance_type": {"id": "automatic"},
    "instances" : $CLOUD_CONTROLLER_INSTANCES
  },
  "ha_proxy": {
    "instance_type": {"id": "automatic"},
    "instances" : $HA_PROXY_INSTANCES
  },
  "router": {
    "instance_type": {"id": "automatic"},
    "instances" : $ROUTER_INSTANCES
  },
  "mysql_monitor": {
    "instance_type": {"id": "automatic"},
    "instances" : $MYSQL_MONITOR_INSTANCES
  },
  "clock_global": {
    "instance_type": {"id": "automatic"},
    "instances" : $CLOCK_GLOBAL_INSTANCES
  },
  "cloud_controller_worker": {
    "instance_type": {"id": "automatic"},
    "instances" : $CLOUD_CONTROLLER_WORKER_INSTANCES
  },
  "diego_database": {
    "instance_type": {"id": "automatic"},
    "instances" : $DIEGO_DATABASE_INSTANCES
  },
  "diego_brain": {
    "instance_type": {"id": "automatic"},
    "instances" : $DIEGO_BRAIN_INSTANCES
  },
  "diego_cell": {
    "instance_type": {"id": "automatic"},
    "instances" : $DIEGO_CELL_INSTANCES
  },
  "doppler": {
    "instance_type": {"id": "automatic"},
    "instances" : $DOPPLER_INSTANCES
  },
  "loggregator_trafficcontroller": {
    "instance_type": {"id": "automatic"},
    "instances" : $LOGGREGATOR_TC_INSTANCES
  },
  "tcp_router": {
    "instance_type": {"id": "automatic"},
    "instances" : $TCP_ROUTER_INSTANCES
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n cf -p "$CF_PROPERTIES" -pn "$CF_NETWORK" -pr "$CF_RESOURCES"

if [[ "$AUTHENTICATION_MODE" == "internal" ]]; then
echo "Configuring Internal Authentication in ERT..."
CF_AUTH_PROPERTIES=$(cat <<-EOF
{
  ".properties.uaa": {
    "value": "$AUTHENTICATION_MODE"
  }
}
EOF
)

elif [[ "$AUTHENTICATION_MODE" == "ldap" ]]; then
echo "Configuring LDAP Authentication in ERT..."
CF_AUTH_PROPERTIES=$(cat <<-EOF
{
  ".properties.uaa": {
    "value": "ldap"
  },
  ".properties.uaa.ldap.url": {
    "value": "$LDAP_URL"
  },
  ".properties.uaa.ldap.credentials": {
    "value": {
      "identity": "$LDAP_USER",
      "password": "$LDAP_PWD"
    }
  },
  ".properties.uaa.ldap.search_base": {
    "value": "$SEARCH_BASE"
  },
  ".properties.uaa.ldap.search_filter": {
    "value": "$SEARCH_FILTER"
  },
  ".properties.uaa.ldap.group_search_base": {
    "value": "$GROUP_SEARCH_BASE"
  },
  ".properties.uaa.ldap.group_search_filter": {
    "value": "$GROUP_SEARCH_FILTER"
  },
  ".properties.uaa.ldap.mail_attribute_name": {
    "value": "$MAIL_ATTR_NAME"
  },
  ".properties.uaa.ldap.first_name_attribute": {
    "value": "$FIRST_NAME_ATTR"
  },
  ".properties.uaa.ldap.last_name_attribute": {
    "value": "$LAST_NAME_ATTR"
  }
}
EOF
)

fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n cf -p "$CF_AUTH_PROPERTIES"

if [[ ! -z "$SYSLOG_HOST" ]]; then

echo "Configuring Syslog in ERT..."

CF_SYSLOG_PROPERTIES=$(cat <<-EOF
{
  ".doppler.message_drain_buffer_size": {
    "value": $SYSLOG_DRAIN_BUFFER_SIZE
  },
  ".cloud_controller.security_event_logging_enabled": {
    "value": $ENABLE_SECURITY_EVENT_LOGGING
  },
  ".properties.syslog_host": {
    "value": "$SYSLOG_HOST"
  },
  ".properties.syslog_port": {
    "value": "$SYSLOG_PORT"
  },
  ".properties.syslog_protocol": {
    "value": "$SYSLOG_PROTOCOL"
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n cf -p "$CF_SYSLOG_PROPERTIES"

fi

if [[ ! -z "$SMTP_ADDRESS" ]]; then

echo "Configuraing SMTP in ERT..."

CF_SMTP_PROPERTIES=$(cat <<-EOF
{
  ".properties.smtp_from": {
    "value": "$SMTP_FROM"
  },
  ".properties.smtp_address": {
    "value": "$SMTP_ADDRESS"
  },
  ".properties.smtp_port": {
    "value": "$SMTP_PORT"
  },
  ".properties.smtp_credentials": {
    "value": {
      "identity": "$SMTP_USER",
      "password": "$SMTP_PWD"
    }
  },
  ".properties.smtp_enable_starttls_auto": {
    "value": true
  },
  ".properties.smtp_auth_mechanism": {
    "value": "$SMTP_AUTH_MECHANISM"
  }
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n cf -p "$CF_SMTP_PROPERTIES"

fi

if [[ "$SSL_TERMINATION" == "haproxy" ]]; then

echo "Terminating SSL on HAProxy"
CF_SSL_TERM_PROPERTIES=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "haproxy"
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

elif [[ "$SSL_TERMINATION" == "external_ssl" ]]; then
echo "Terminating SSL on GoRouters"

CF_SSL_TERM_PROPERTIES=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "external_ssl"
  },
  ".properties.networking_point_of_entry.external_ssl.ssl_rsa_certificate": {
    "value": {
      "cert_pem": "$SSL_CERT",
      "private_key_pem": "$SSL_PRIVATE_KEY"
    }
  }
}
EOF
)

elif [[ "$SSL_TERMINATION" == "external_non_ssl" ]]; then
echo "Terminating SSL on Load Balancers"
CF_SSL_TERM_PROPERTIES=$(cat <<-EOF
{
  ".properties.networking_point_of_entry": {
    "value": "external_non_ssl"
  }
}
EOF
)

fi

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n cf -p "$CF_SSL_TERM_PROPERTIES"
