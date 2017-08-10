#!/bin/bash

set -eu

source pcf-pipelines/functions/generate_cert.sh

if [[ -z "$SSL_CERT" ]]; then
  domains=(
    "*.${SYSTEM_DOMAIN}"
    "*.${APPS_DOMAIN}"
    "*.login.${SYSTEM_DOMAIN}"
    "*.uaa.${SYSTEM_DOMAIN}"
  )

  certificates=$(generate_cert "${domains[*]}")
  SSL_CERT=`echo $certificates | jq --raw-output '.certificate'`
  SSL_PRIVATE_KEY=`echo $certificates | jq --raw-output '.key'`
fi


if [[ -z "$SAML_SSL_CERT" ]]; then
  saml_cert_domains=(
    "*.${SYSTEM_DOMAIN}"
    "*.login.${SYSTEM_DOMAIN}"
    "*.uaa.${SYSTEM_DOMAIN}"
  )

  saml_certificates=$(generate_cert "${saml_cert_domains[*]}")
  SAML_SSL_CERT=$(echo $saml_certificates | jq --raw-output '.certificate')
  SAML_SSL_PRIVATE_KEY=$(echo $saml_certificates | jq --raw-output '.key')
fi

cf_properties=$(
  jq -n \
    --arg tcp_routing "$TCP_ROUTING" \
    --arg tcp_routing_ports "$TCP_ROUTING_PORTS" \
    --arg loggregator_endpoint_port "$LOGGREGATOR_ENDPOINT_PORT" \
    --arg route_services "$ROUTE_SERVICES" \
    --arg ignore_ssl_cert "$IGNORE_SSL_CERT" \
    --arg security_acknowledgement "$SECURITY_ACKNOWLEDGEMENT" \
    --arg system_domain "$SYSTEM_DOMAIN" \
    --arg apps_domain "$APPS_DOMAIN" \
    --arg default_quota_memory_limit_in_mb "$DEFAULT_QUOTA_MEMORY_LIMIT_IN_MB" \
    --arg default_quota_max_services_count "$DEFAULT_QUOTA_MAX_SERVICES_COUNT" \
    --arg allow_app_ssh_access "$ALLOW_APP_SSH_ACCESS" \
    --arg ha_proxy_ips "$HA_PROXY_IPS" \
    --arg skip_cert_verify "$SKIP_CERT_VERIFY" \
    --arg router_static_ips "$ROUTER_STATIC_IPS" \
    --arg disable_insecure_cookies "$DISABLE_INSECURE_COOKIES" \
    --arg router_request_timeout_seconds "$ROUTER_REQUEST_TIMEOUT_IN_SEC" \
    --arg mysql_monitor_email "$MYSQL_MONITOR_EMAIL" \
    --arg tcp_router_static_ips "$TCP_ROUTER_STATIC_IPS" \
    --arg company_name "$COMPANY_NAME" \
    --arg ssh_static_ips "$SSH_STATIC_IPS" \
    --arg cert_pem "$SSL_CERT" \
    --arg private_key_pem "$SSL_PRIVATE_KEY" \
    --arg ssl_termination "$SSL_TERMINATION" \
    --arg smtp_from "$SMTP_FROM" \
    --arg smtp_address "$SMTP_ADDRESS" \
    --arg smtp_port "$SMTP_PORT" \
    --arg smtp_user "$SMTP_USER" \
    --arg smtp_password "$SMTP_PWD" \
    --arg smtp_auth_mechanism "$SMTP_AUTH_MECHANISM" \
    --arg enable_security_event_logging "$ENABLE_SECURITY_EVENT_LOGGING" \
    --arg syslog_host "$SYSLOG_HOST" \
    --arg syslog_drain_buffer_size "$SYSLOG_DRAIN_BUFFER_SIZE" \
    --arg syslog_port "$SYSLOG_PORT" \
    --arg syslog_protocol "$SYSLOG_PROTOCOL" \
    --arg authentication_mode "$AUTHENTICATION_MODE" \
    --arg ldap_url "$LDAP_URL" \
    --arg ldap_user "$LDAP_USER" \
    --arg ldap_password "$LDAP_PWD" \
    --arg ldap_search_base "$SEARCH_BASE" \
    --arg ldap_search_filter "$SEARCH_FILTER" \
    --arg ldap_group_search_base "$GROUP_SEARCH_BASE" \
    --arg ldap_group_search_filter "$GROUP_SEARCH_FILTER" \
    --arg ldap_mail_attr_name "$MAIL_ATTR_NAME" \
    --arg ldap_first_name_attr "$FIRST_NAME_ATTR" \
    --arg ldap_last_name_attr "$LAST_NAME_ATTR" \
    --arg saml_cert_pem "$SAML_SSL_CERT" \
    --arg saml_key_pem "$SAML_SSL_PRIVATE_KEY" \
    --arg mysql_backups "$MYSQL_BACKUPS" \
    --arg mysql_backups_s3_endpoint_url "$MYSQL_BACKUPS_S3_ENDPOINT_URL" \
    --arg mysql_backups_s3_bucket_name "$MYSQL_BACKUPS_S3_BUCKET_NAME" \
    --arg mysql_backups_s3_bucket_path "$MYSQL_BACKUPS_S3_BUCKET_PATH" \
    --arg mysql_backups_s3_access_key_id "$MYSQL_BACKUPS_S3_ACCESS_KEY_ID" \
    --arg mysql_backups_s3_secret_access_key "$MYSQL_BACKUPS_S3_SECRET_ACCESS_KEY" \
    --arg mysql_backups_s3_cron_schedule "$MYSQL_BACKUPS_S3_CRON_SCHEDULE" \
    --arg mysql_backups_scp_server "$MYSQL_BACKUPS_SCP_SERVER" \
    --arg mysql_backups_scp_port "$MYSQL_BACKUPS_SCP_PORT" \
    --arg mysql_backups_scp_user "$MYSQL_BACKUPS_SCP_USER" \
    --arg mysql_backups_scp_key "$MYSQL_BACKUPS_SCP_KEY" \
    --arg mysql_backups_scp_destination "$MYSQL_BACKUPS_SCP_DESTINATION" \
    --arg mysql_backups_scp_cron_schedule "$MYSQL_BACKUPS_SCP_CRON_SCHEDULE" \
    '
    {
      ".properties.system_blobstore": {
        "value": "internal"
      },
      ".properties.logger_endpoint_port": {
        "value": $loggregator_endpoint_port
      },
      ".properties.route_services": {
        "value": $route_services
      },
      ".properties.route_services.enable.ignore_ssl_cert_verification": {
        "value": $ignore_ssl_cert
      },
      ".properties.security_acknowledgement": {
        "value": $security_acknowledgement
      },
      ".cloud_controller.system_domain": {
        "value": $system_domain
      },
      ".cloud_controller.apps_domain": {
        "value": $apps_domain
      },
      ".cloud_controller.default_quota_memory_limit_mb": {
        "value": $default_quota_memory_limit_in_mb
      },
      ".cloud_controller.default_quota_max_number_services": {
        "value": $default_quota_max_services_count
      },
      ".cloud_controller.allow_app_ssh_access": {
        "value": $allow_app_ssh_access
      },
      ".ha_proxy.static_ips": {
        "value": $ha_proxy_ips
      },
      ".ha_proxy.skip_cert_verify": {
        "value": $skip_cert_verify
      },
      ".router.static_ips": {
        "value": $router_static_ips
      },
      ".router.disable_insecure_cookies": {
        "value": $disable_insecure_cookies
      },
      ".router.request_timeout_in_seconds": {
        "value": $router_request_timeout_seconds
      },
      ".mysql_monitor.recipient_email": {
        "value": $mysql_monitor_email
      },
      ".tcp_router.static_ips": {
        "value": $tcp_router_static_ips
      },
      ".push-apps-manager.company_name": {
        "value": $company_name
      },
      ".diego_brain.static_ips": {
        "value": $ssh_static_ips
      }
    }

    +

    # TCP Routing
    if $tcp_routing == "enable" then
     {
       ".properties.tcp_routing": {
          "value": "enable"
        },
        ".properties.tcp_routing.enable.reservable_ports": {
          "value": $tcp_routing_ports
        }
      }
    else
      {
        ".properties.tcp_routing": {
          "value": "disable"
        }
      }
    end

    +

    # SSL Termination
    if $ssl_termination == "haproxy" then
      {
        ".properties.networking_point_of_entry": {
          "value": "haproxy"
        },
        ".properties.networking_point_of_entry.haproxy.ssl_rsa_certificate": {
          "value": {
            "cert_pem": $cert_pem,
            "private_key_pem": $private_key_pem
          }
        }
      }
    elif $ssl_termination == "external_ssl" then
      {
        ".properties.networking_point_of_entry": {
          "value": "external_ssl"
        },
        ".properties.networking_point_of_entry.external_ssl.ssl_rsa_certificate": {
          "value": {
            "cert_pem": $cert_pem,
            "private_key_pem": $private_key_pem
          }
        }
      }
    else
      {
        ".properties.networking_point_of_entry": {
          "value": "external_non_ssl"
        }
      }
    end

    +

    # SMTP Configuration
    if $smtp_address != "" then
      {
        ".properties.smtp_from": {
          "value": $smtp_from
        },
        ".properties.smtp_address": {
          "value": $smtp_address
        },
        ".properties.smtp_port": {
          "value": $smtp_port
        },
        ".properties.smtp_credentials": {
          "value": {
            "identity": $smtp_user,
            "password": $smtp_password
          }
        },
        ".properties.smtp_enable_starttls_auto": {
          "value": true
        },
        ".properties.smtp_auth_mechanism": {
          "value": $smtp_auth_mechanism
        }
      }
    else
      .
    end

    +

    # Syslog
    if $syslog_host != "" then
      {
        ".doppler.message_drain_buffer_size": {
          "value": $syslog_drain_buffer_size
        },
        ".cloud_controller.security_event_logging_enabled": {
          "value": $enable_security_event_logging
        },
        ".properties.syslog_host": {
          "value": $syslog_host
        },
        ".properties.syslog_port": {
          "value": $syslog_port
        },
        ".properties.syslog_protocol": {
          "value": $syslog_protocol
        }
      }
    else
      .
    end

    +

    # Authentication
    if $authentication_mode == "internal" then
      {
        ".properties.uaa": {
          "value": "internal"
        }
      }
    elif $authentication_mode == "ldap" then
      {
        ".properties.uaa": {
          "value": "ldap"
        },
        ".properties.uaa.ldap.url": {
          "value": $ldap_url
        },
        ".properties.uaa.ldap.credentials": {
          "value": {
            "identity": $ldap_user,
            "password": $ldap_password
          }
        },
        ".properties.uaa.ldap.search_base": {
          "value": $ldap_search_base
        },
        ".properties.uaa.ldap.search_filter": {
          "value": $ldap_search_filter
        },
        ".properties.uaa.ldap.group_search_base": {
          "value": $ldap_group_search_base
        },
        ".properties.uaa.ldap.group_search_filter": {
          "value": $ldap_group_search_filter
        },
        ".properties.uaa.ldap.mail_attribute_name": {
          "value": $ldap_mail_attr_name
        },
        ".properties.uaa.ldap.first_name_attribute": {
          "value": $ldap_first_name_attr
        },
        ".properties.uaa.ldap.last_name_attribute": {
          "value": $ldap_last_name_attr
        }
      }
    else
      .
    end

    +

    # UAA SAML Credentials
    {
      ".uaa.service_provider_key_credentials": {
        value: {
          "cert_pem": $saml_cert_pem,
          "private_key_pem": $saml_key_pem
        }
      }
    }

    +

    # MySQL Backups
    if $mysql_backups == "s3" then
      {
        ".properties.mysql_backups": {
          "value": "s3"
        },
        ".properties.mysql_backups.s3.endpoint_url":  {
          "value": $mysql_backups_s3_endpoint_url
        },
        ".properties.mysql_backups.s3.bucket_name":  {
          "value": $mysql_backups_s3_bucket_name
        },
        ".properties.mysql_backups.s3.bucket_path":  {
          "value": $mysql_backups_s3_bucket_path
        },
        ".properties.mysql_backups.s3.access_key_id":  {
          "value": $mysql_backups_s3_access_key_id
        },
        ".properties.mysql_backups.s3.secret_access_key":  {
          "value": $mysql_backups_s3_secret_access_key
        },
        ".properties.mysql_backups.s3.cron_schedule":  {
          "value": $mysql_backups_s3_cron_schedule
        }
      }
    elif $mysql_backups == "scp" then
      {
        ".properties.mysql_backups": {
          "value": "scp"
        },
        ".properties.mysql_backups.scp.server": {
          "value": $mysql_backups_scp_server
        },
        ".properties.mysql_backups.scp.port": {
          "value": $mysql_backups_scp_port
        },
        ".properties.mysql_backups.scp.user": {
          "value": $mysql_backups_scp_user
        },
        ".properties.mysql_backups.scp.key": {
          "value": $mysql_backups_scp_key
        },
        ".properties.mysql_backups.scp.destination": {
          "value": $mysql_backups_scp_destination
        },
        ".properties.mysql_backups.scp.cron_schedule" : {
          "value": $mysql_backups_scp_cron_schedule
        }
      }
    else
      .
    end
    '
)

cf_network=$(
  jq -n \
    --arg network_name "$NETWORK_NAME" \
    --arg other_azs "$DEPLOYMENT_NW_AZS" \
    --arg singleton_az "$ERT_SINGLETON_JOB_AZ" \
    '
    {
      "network": {
        "name": $network_name
      },
      "other_availability_zones": ($other_azs | split(",") | map({name: .})),
      "singleton_availability_zone": {
        "name": $singleton_az
      }
    }
    '
)

cf_resources=$(
  jq -n \
    --argjson consul_server_instances $CONSUL_SERVER_INSTANCES \
    --argjson nats_instances $NATS_INSTANCES \
    --argjson etcd_tls_server_instances $ETCD_TLS_SERVER_INSTANCES \
    --argjson nfs_server_instances $NFS_SERVER_INSTANCES \
    --argjson mysql_proxy_instances $MYSQL_PROXY_INSTANCES \
    --argjson mysql_instances $MYSQL_INSTANCES \
    --argjson backup_prepare_instances $BACKUP_PREPARE_INSTANCES \
    --argjson ccdb_instances $CCDB_INSTANCES \
    --argjson diego_database_instances $DIEGO_DATABASE_INSTANCES \
    --argjson uaadb_instances $UAADB_INSTANCES \
    --argjson uaa_instances $UAA_INSTANCES \
    --argjson cloud_controller_instances $CLOUD_CONTROLLER_INSTANCES \
    --argjson ha_proxy_instances $HA_PROXY_INSTANCES \
    --argjson router_instances $ROUTER_INSTANCES \
    --argjson mysql_monitor_instances $MYSQL_MONITOR_INSTANCES \
    --argjson clock_global_instances $CLOCK_GLOBAL_INSTANCES \
    --argjson cloud_controller_worker_instances $CLOUD_CONTROLLER_WORKER_INSTANCES \
    --argjson diego_brain_instances $DIEGO_BRAIN_INSTANCES \
    --argjson diego_cell_instances $DIEGO_CELL_INSTANCES \
    --argjson loggregator_tc_instances $LOGGREGATOR_TC_INSTANCES \
    --argjson tcp_router_instances $TCP_ROUTER_INSTANCES \
    --argjson syslog_adapter_instances $SYSLOG_ADAPTER_INSTANCES \
    --argjson syslog_scheduler_instances $SYSLOG_SCHEDULER_INSTANCES \
    --argjson doppler_instances $DOPPLER_INSTANCES \
    --arg tcp_router_nsx_security_group "${TCP_ROUTER_NSX_SECURITY_GROUP}" \
    --arg tcp_router_nsx_lb_edge_name "${TCP_ROUTER_NSX_LB_EDGE_NAME}" \
    --arg tcp_router_nsx_lb_pool_name "${TCP_ROUTER_NSX_LB_POOL_NAME}" \
    --arg tcp_router_nsx_lb_security_group "${TCP_ROUTER_NSX_LB_SECURITY_GROUP}" \
    --arg tcp_router_nsx_lb_port "${TCP_ROUTER_NSX_LB_PORT}" \
    --arg router_nsx_security_group "${ROUTER_NSX_SECURITY_GROUP}" \
    --arg router_nsx_lb_edge_name "${ROUTER_NSX_LB_EDGE_NAME}" \
    --arg router_nsx_lb_pool_name "${ROUTER_NSX_LB_POOL_NAME}" \
    --arg router_nsx_lb_security_group "${ROUTER_NSX_LB_SECURITY_GROUP}" \
    --arg router_nsx_lb_port "${ROUTER_NSX_LB_PORT}" \
    --arg diego_brain_nsx_security_group "${DIEGO_BRAIN_NSX_SECURITY_GROUP}" \
    --arg diego_brain_nsx_lb_edge_name "${DIEGO_BRAIN_NSX_LB_EDGE_NAME}" \
    --arg diego_brain_nsx_lb_pool_name "${DIEGO_BRAIN_NSX_LB_POOL_NAME}" \
    --arg diego_brain_nsx_lb_security_group "${DIEGO_BRAIN_NSX_LB_SECURITY_GROUP}" \
    --arg diego_brain_nsx_lb_port "${DIEGO_BRAIN_NSX_LB_PORT}" \
    '
    {
      "consul_server": { "instances": $consul_server_instances },
      "nats": { "instances": $nats_instances },
      "etcd_tls_server": { "instances": $etcd_tls_server_instances },
      "nfs_server": { "instances": $nfs_server_instances },
      "mysql_proxy": { "instances": $mysql_proxy_instances },
      "mysql": { "instances": $mysql_instances },
      "backup-prepare": { "instances": $backup_prepare_instances },
      "ccdb": { "instances": $ccdb_instances },
      "diego_database": { "instances": $diego_database_instances },
      "uaadb": { "instances": $uaadb_instances },
      "uaa": { "instances": $uaa_instances },
      "cloud_controller": { "instances": $cloud_controller_instances },
      "ha_proxy": { "instances": $ha_proxy_instances },
      "router": { "instances": $router_instances },
      "mysql_monitor": { "instances": $mysql_monitor_instances },
      "clock_global": { "instances": $clock_global_instances },
      "cloud_controller_worker": { "instances": $cloud_controller_worker_instances },
      "diego_brain": { "instances": $diego_brain_instances },
      "diego_cell": { "instances": $diego_cell_instances },
      "loggregator_trafficcontroller": { "instances": $loggregator_tc_instances },
      "tcp_router": { "instances": $tcp_router_instances },
      "syslog_adapter": { "instances": $syslog_adapter_instances },
      "syslog_scheduler": { "instances": $syslog_scheduler_instances },
      "doppler": { "instances": $doppler_instances }
    }

    |

    # NSX LBs

    if $tcp_router_nsx_lb_edge_name != "" then
      .tcp_router |= . + {
        "nsx_security_groups": [$tcp_router_nsx_security_group],
        "nsx_lbs": [
          {
            "edge_name": $tcp_router_nsx_lb_edge_name,
            "pool_name": $tcp_router_nsx_lb_pool_name,
            "security_group": $tcp_router_nsx_lb_security_group,
            "port": $tcp_router_nsx_lb_port
          }
        ]
      }
    else
      .
    end

    |

    if $router_nsx_lb_edge_name != "" then
      .router |= . + {
        "nsx_security_groups": [$router_nsx_security_group],
        "nsx_lbs": [
          {
            "edge_name": $router_nsx_lb_edge_name,
            "pool_name": $router_nsx_lb_pool_name,
            "security_group": $router_nsx_lb_security_group,
            "port": $router_nsx_lb_port
          }
        ]
      }
    else
      .
    end

    |

    if $diego_brain_nsx_lb_edge_name != "" then
      .diego_brain |= . + {
        "nsx_security_groups": [$diego_brain_nsx_security_group],
        "nsx_lbs": [
          {
            "edge_name": $diego_brain_nsx_lb_edge_name,
            "pool_name": $diego_brain_nsx_lb_pool_name,
            "security_group": $diego_brain_nsx_lb_security_group,
            "port": $diego_brain_nsx_lb_port
          }
        ]
      }
    else
      .
    end
    '
)

om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --username $OPS_MGR_USR \
  --password $OPS_MGR_PWD \
  --skip-ssl-validation \
  configure-product \
  --product-name cf \
  --product-properties "$cf_properties" \
  --product-network "$cf_network" \
  --product-resources "$cf_resources"
