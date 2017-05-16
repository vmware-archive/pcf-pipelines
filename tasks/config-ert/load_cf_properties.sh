#!/bin/bash -e

if [[ -n "$TCP_ROUTING" ]] && [[ "$TCP_ROUTING" == "enable" ]]; then
CF_TCP_ROUTING_PROPERTIES=$(cat <<-EOF
  ".properties.tcp_routing": {
    "value": "$TCP_ROUTING"
  },
  ".properties.tcp_routing.enable.reservable_ports": {
    "value": "$TCP_ROUTING_PORTS"
  }
EOF
)
else 
CF_TCP_ROUTING_PROPERTIES=$(cat <<-EOF
  ".properties.tcp_routing": {
    "value": "disable"
  }
EOF
)
fi

CF_PROPERTIES=$(cat <<-EOF
{
  ".properties.logger_endpoint_port": {
    "value": "$LOGGREGATOR_ENDPOINT_PORT"
  },
  $CF_TCP_ROUTING_PROPERTIES
  ,
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

if [[ ${MYSQL_BACKUPS} == "scp" ]]; then
echo "adding scp mysql backup properties"
CF_PROPERTIES=$(echo "${CF_PROPERTIES}" | 
  jq '.".properties.mysql_backups.scp.server" = {"value": "'${MYSQL_BACKUPS_SCP_SERVER}'"}' |
  jq '.".properties.mysql_backups.scp.port" = {"value": "'${MYSQL_BACKUPS_SCP_PORT}'"}' |
  jq '.".properties.mysql_backups.scp.user" = {"value": "'${MYSQL_BACKUPS_SCP_USER}'"}' |
  jq '.".properties.mysql_backups.scp.key" = {"value": "'${MYSQL_BACKUPS_SCP_KEY}'"}' |
  jq '.".properties.mysql_backups.scp.destination" = {"value": "'${MYSQL_BACKUPS_SCP_DESTINATION}'"}' |
  jq '.".properties.mysql_backups.scp.cron_schedule" = {"value": "'${MYSQL_BACKUPS_SCP_CRON_SCHEDULE}'"}')
fi
