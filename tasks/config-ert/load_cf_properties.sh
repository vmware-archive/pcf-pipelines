#!/bin/bash

echo '{}' |
jq \
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
  --arg saml_cert_pem "$saml_cert_pem" \
  --arg saml_key_pem "$saml_key_pem" \
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
  . +
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
  ' > cf_properties

cf_properties=$(cat cf_properties)
