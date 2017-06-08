#!/bin/bash -e

echo "checking for 1.11 compatibility..."
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }
STAGED_ERT_VERSION=$(om-linux   --target "https://${OPSMAN_URI}"   --skip-ssl-validation   --username "${OPSMAN_USERNAME}"   --password "${OPSMAN_PASSWORD}" staged-products  --ignore-warnings | grep "| cf" | awk '{ print $4}')
TOGGLE_VERSION=1.11
DIEGO_NETWORK_SETTINGS=""
if version_gt $TOGGLE_VERSION $STAGED_ERT_VERSION; then
     echo "$TOGGLE_VERSION is greater than $STAGED_ERT_VERSION ! loading a config compatible with <= 1.10 ert"
     DIEGO_NETWORK_SETTINGS='".diego_cell.garden_network_pool": {"value": "$GARDEN_NETWORK_POOL_CIDR"},'
fi
echo "finished 1.11 compatibility check"

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
  $DIEGO_NETWORK_SETTINGS
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
  cat > mysql_filter <<-'EOF'
    .".properties.mysql_backups" = {"value": $mysql_backups} |
    .".properties.mysql_backups.scp.server" = {"value": $mysql_backups_scp_server} |
    .".properties.mysql_backups.scp.port" = {"value": $mysql_backups_scp_port} |
    .".properties.mysql_backups.scp.user" = {"value": $mysql_backups_scp_user} |
    .".properties.mysql_backups.scp.key" = {"value": $mysql_backups_scp_key} |
    .".properties.mysql_backups.scp.destination" = {"value": $mysql_backups_scp_destination} |
    .".properties.mysql_backups.scp.cron_schedule" = {"value": $mysql_backups_scp_cron_schedule}
EOF

  echo "${CF_PROPERTIES}" | jq \
    --arg mysql_backups "$MYSQL_BACKUPS" \
    --arg mysql_backups_scp_server "$MYSQL_BACKUPS_SCP_SERVER" \
    --arg mysql_backups_scp_port "$MYSQL_BACKUPS_SCP_PORT" \
    --arg mysql_backups_scp_user "$MYSQL_BACKUPS_SCP_USER" \
    --arg mysql_backups_scp_key "$MYSQL_BACKUPS_SCP_KEY" \
    --arg mysql_backups_scp_destination "$MYSQL_BACKUPS_SCP_DESTINATION" \
    --arg mysql_backups_scp_cron_schedule "$MYSQL_BACKUPS_SCP_CRON_SCHEDULE" \
    --from-file mysql_filter > config.json
  CF_PROPERTIES=$(cat config.json)
fi

if [[ ${MYSQL_BACKUPS} == "s3" ]]; then
  echo "adding s3 mysql backup properties"
  cat > mysql_filter <<-'EOF'
    .".properties.mysql_backups" = {"value": $mysql_backups} |
    .".properties.mysql_backups.s3.endpoint_url" = {"value": $mysql_backups_s3_endpoint_url} |
    .".properties.mysql_backups.s3.bucket_name" = {"value": $mysql_backups_s3_bucket_name} |
    .".properties.mysql_backups.s3.bucket_path" = {"value": $mysql_backups_s3_bucket_path} |
    .".properties.mysql_backups.s3.access_key_id" = {"value": $mysql_backups_s3_access_key_id} |
    .".properties.mysql_backups.s3.secret_access_key" = {"value": $mysql_backups_s3_secret_access_key} |
    .".properties.mysql_backups.s3.cron_schedule" = {"value": $mysql_backups_s3_cron_schedule}
EOF

  echo "${CF_PROPERTIES}" | jq \
    --arg mysql_backups "$MYSQL_BACKUPS" \
    --arg mysql_backups_s3_endpoint_url "$MYSQL_BACKUPS_S3_ENDPOINT_URL" \
    --arg mysql_backups_s3_bucket_name "$MYSQL_BACKUPS_S3_BUCKET_NAME" \
    --arg mysql_backups_s3_bucket_path "$MYSQL_BACKUPS_S3_BUCKET_PATH" \
    --arg mysql_backups_s3_access_key_id "$MYSQL_BACKUPS_S3_ACCESS_KEY_ID" \
    --arg mysql_backups_s3_secret_access_key "$MYSQL_BACKUPS_S3_SECRET_ACCESS_KEY" \
    --arg mysql_backups_s3_cron_schedule "$MYSQL_BACKUPS_S3_CRON_SCHEDULE" \
    --from-file mysql_filter > config.json
  CF_PROPERTIES=$(cat config.json)
fi
