#!/bin/bash
set -eu

export OPSMAN_DOMAIN_OR_IP_ADDRESS="opsman.$pcf_ert_domain"

source pcf-pipelines/functions/generate_cert.sh

if [[ ${pcf_ert_ssl_cert} == "" || ${pcf_ert_ssl_cert} == "generate" ]]; then
  domains=(
    "*.sys.${pcf_ert_domain}"
    "*.cfapps.${pcf_ert_domain}"
  )

  certificates=$(generate_cert "${domains[*]}")
  pcf_ert_ssl_cert=`echo $certificates | jq --raw-output '.certificate'`
  pcf_ert_ssl_key=`echo $certificates | jq --raw-output '.key'`
fi

saml_domains=(
  "*.sys.${pcf_ert_domain}"
  "*.login.sys.${pcf_ert_domain}"
  "*.uaa.sys.${pcf_ert_domain}"
)

saml_certificates=$(generate_cert "${saml_domains[*]}")
saml_cert_pem=`echo $saml_certificates | jq --raw-output '.certificate'`
saml_key_pem=`echo $saml_certificates | jq --raw-output '.key'`

if [[ "${pcf_iaas}" == "aws" ]]; then
  cd terraform-state
    output_json=$(terraform output --json -state *.tfstate)
    db_host=$(echo $output_json | jq --raw-output '.db_host.value')
    aws_region=$(echo $output_json | jq --raw-output '.region.value')
    aws_access_key=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^id | awk '{print $3}'`
    aws_secret_key=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^secret | awk '{print $3}'`
  cd -
elif [[ "${pcf_iaas}" == "gcp" ]]; then
  cd terraform-state
    db_host=$(terraform output --json -state *.tfstate | jq --raw-output '.sql_instance_ip.value')
  cd -

  if [ -z "$db_host" ]; then
    echo Failed to get SQL instance IP from Terraform state file
    exit 1
  fi
elif [[ "${pcf_iaas}" == "azure" ]]; then
  cd terraform-state
    db_host=$(terraform output --json -state *.tfstate | jq --raw-output '.mysql_dns.value')
  cd -
fi

cf_network=$(
  jq -n \
    --arg iaas $pcf_iaas \
    --arg singleton_availability_zone "$pcf_az_1" \
    --arg other_availability_zones "$pcf_az_1,$pcf_az_2,$pcf_az_3" \
    '
    {
      "network": {
        "name": (if $iaas == "aws" then "deployment" else "ert" end),
      },
      "other_availability_zones": ($other_availability_zones | split(",") | map({name: .})),
      "singleton_availability_zone": {
        "name": $singleton_availability_zone
      }
    }
    '
)

cf_resources=$(
  jq -n \
    --arg terraform_prefix $terraform_prefix \
    --arg iaas $pcf_iaas \
    '
    {
      "consul_server": {"internet_connected": false},
      "nats": {"internet_connected": false},
      "nfs_server": {"internet_connected": false},
      "mysql_proxy": {
        "instances": 0,
        "internet_connected": false
      },
      "mysql": {
        "instances": 0,
        "internet_connected": false
      },
      "backup-prepare": {"internet_connected": false},
      "diego_database": {"internet_connected": false},
      "uaa": {"internet_connected": false},
      "cloud_controller": {"internet_connected": false},
      "ha_proxy": {"internet_connected": false},
      "router": {"internet_connected": false},
      "mysql_monitor": {
        "instances": 0,
        "internet_connected": false
      },
      "clock_global": {"internet_connected": false},
      "cloud_controller_worker": {"internet_connected": false},
      "diego_brain": {"internet_connected": false},
      "diego_cell": {"internet_connected": false},
      "loggregator_trafficcontroller": {"internet_connected": false},
      "syslog_adapter": {"internet_connected": false},
      "syslog_scheduler": {"internet_connected": false},
      "doppler": {"internet_connected": false},
      "tcp_router": {"internet_connected": false},
      "smoke-tests": {"internet_connected": false},
      "push-apps-manager": {"internet_connected": false},
      "notifications": {"internet_connected": false},
      "notifications-ui": {"internet_connected": false},
      "push-pivotal-account": {"internet_connected": false},
      "autoscaling": {"internet_connected": false},
      "autoscaling-register-broker": {"internet_connected": false},
      "nfsbrokerpush": {"internet_connected": false},
      "bootstrap": {"internet_connected": false},
      "mysql-rejoin-unsafe": {"internet_connected": false}
    }

    |

    # ELBs

    if $iaas == "aws" then
      .router |= . + { "elb_names": ["\($terraform_prefix)-Pcf-Http-Elb"] }
      | .diego_brain |= . + { "elb_names": ["\($terraform_prefix)-Pcf-Ssh-Elb"] }
    elif $iaas == "gcp" then
      .router |= . + { "elb_names": ["http:\($terraform_prefix)-http-lb-backend","tcp:\($terraform_prefix)-wss-logs"] }
      | .diego_brain |= . + { "elb_names": ["tcp:\($terraform_prefix)-ssh-proxy"] }
    else
      .
    end
    '
)

cf_properties=$(
  jq -n \
    --arg terraform_prefix $terraform_prefix \
    --arg singleton_availability_zone "$pcf_az_1" \
    --arg other_availability_zones "$pcf_az_1,$pcf_az_2,$pcf_az_3" \
    --arg cert_pem "$pcf_ert_ssl_cert" \
    --arg private_key_pem "$pcf_ert_ssl_key" \
    --arg saml_cert_pem "$saml_cert_pem" \
    --arg saml_key_pem "$saml_key_pem" \
    --arg haproxy_forward_tls "$HAPROXY_FORWARD_TLS" \
    --arg haproxy_backend_ca "$HAPROXY_BACKEND_CA" \
    --arg router_tls_ciphers "$ROUTER_TLS_CIPHERS" \
    --arg haproxy_tls_ciphers "$HAPROXY_TLS_CIPHERS" \
    --arg routing_disable_http "$routing_disable_http" \
    --arg iaas $pcf_iaas \
    --arg pcf_ert_domain "$pcf_ert_domain" \
    --arg mysql_monitor_recipient_email "$mysql_monitor_recipient_email" \
    --arg db_host "$db_host" \
    --arg db_locket_username "$db_locket_username" \
    --arg db_locket_password "$db_locket_password" \
    --arg db_silk_username "$db_silk_username" \
    --arg db_silk_password "$db_silk_password" \
    --arg db_app_usage_service_username "$db_app_usage_service_username" \
    --arg db_app_usage_service_password "$db_app_usage_service_password" \
    --arg db_autoscale_username "$db_autoscale_username" \
    --arg db_autoscale_password "$db_autoscale_password" \
    --arg db_diego_username "$db_diego_username" \
    --arg db_diego_password "$db_diego_password" \
    --arg db_notifications_username "$db_notifications_username" \
    --arg db_notifications_password "$db_notifications_password" \
    --arg db_routing_username "$db_routing_username" \
    --arg db_routing_password "$db_routing_password" \
    --arg db_uaa_username "$db_uaa_username" \
    --arg db_uaa_password "$db_uaa_password" \
    --arg db_ccdb_username "$db_ccdb_username" \
    --arg db_ccdb_password "$db_ccdb_password" \
    --arg db_accountdb_username "$db_accountdb_username" \
    --arg db_accountdb_password "$db_accountdb_password" \
    --arg db_networkpolicyserverdb_username "$db_networkpolicyserverdb_username" \
    --arg db_networkpolicyserverdb_password "$db_networkpolicyserverdb_password" \
    --arg db_nfsvolumedb_username "$db_nfsvolumedb_username" \
    --arg db_nfsvolumedb_password "$db_nfsvolumedb_password" \
    --arg s3_endpoint "$S3_ENDPOINT" \
    --arg aws_access_key "${aws_access_key:-''}" \
    --arg aws_secret_key "${aws_secret_key:-''}" \
    --arg aws_region "${aws_region:-''}" \
    --arg gcp_storage_access_key "${gcp_storage_access_key:-''}" \
    --arg gcp_storage_secret_key "${gcp_storage_secret_key:-''}" \
    --arg mysql_backups "$MYSQL_BACKUPS" \
    --arg mysql_backups_scp_server "$MYSQL_BACKUPS_SCP_SERVER" \
    --arg mysql_backups_scp_port "$MYSQL_BACKUPS_SCP_PORT" \
    --arg mysql_backups_scp_user "$MYSQL_BACKUPS_SCP_USER" \
    --arg mysql_backups_scp_key "$MYSQL_BACKUPS_SCP_KEY" \
    --arg mysql_backups_scp_destination "$MYSQL_BACKUPS_SCP_DESTINATION" \
    --arg mysql_backups_scp_cron_schedule "$MYSQL_BACKUPS_SCP_CRON_SCHEDULE" \
    --arg mysql_backups_s3_endpoint_url "$MYSQL_BACKUPS_S3_ENDPOINT_URL" \
    --arg mysql_backups_s3_bucket_name "$MYSQL_BACKUPS_S3_BUCKET_NAME" \
    --arg mysql_backups_s3_bucket_path "$MYSQL_BACKUPS_S3_BUCKET_PATH" \
    --arg mysql_backups_s3_access_key_id "$MYSQL_BACKUPS_S3_ACCESS_KEY_ID" \
    --arg mysql_backups_s3_secret_access_key "$MYSQL_BACKUPS_S3_SECRET_ACCESS_KEY" \
    --arg mysql_backups_s3_cron_schedule "$MYSQL_BACKUPS_S3_CRON_SCHEDULE" \
    '
    {
      ".uaa.service_provider_key_credentials": {
        "value": {
          "cert_pem": $saml_cert_pem,
          "private_key_pem": $saml_key_pem
        }
      },
      ".properties.tcp_routing": { "value": "disable" },
      ".properties.route_services": { "value": "enable" },
      ".ha_proxy.skip_cert_verify": { "value": true },
      ".properties.route_services.enable.ignore_ssl_cert_verification": { "value": true },
      ".properties.security_acknowledgement": { "value": "X" },
      ".properties.system_database": { "value": "external" },
      ".properties.system_database.external.port": { "value": "3306" },
      ".properties.system_database.external.host": { "value": $db_host },
      ".properties.system_database.external.app_usage_service_username": { "value": $db_app_usage_service_username },
      ".properties.system_database.external.app_usage_service_password": { "value": { "secret": $db_app_usage_service_password } },
      ".properties.system_database.external.autoscale_username": { "value": $db_autoscale_username },
      ".properties.system_database.external.autoscale_password": { "value": { "secret": $db_autoscale_password } },
      ".properties.system_database.external.diego_username": { "value": $db_diego_username },
      ".properties.system_database.external.diego_password": { "value": { "secret": $db_diego_password } },
      ".properties.system_database.external.notifications_username": { "value": $db_notifications_username },
      ".properties.system_database.external.notifications_password": { "value": { "secret": $db_notifications_password } },
      ".properties.system_database.external.routing_username": { "value": $db_routing_username },
      ".properties.system_database.external.routing_password": { "value": { "secret": $db_routing_password } },
      ".properties.system_database.external.ccdb_username": { "value": $db_ccdb_username },
      ".properties.system_database.external.ccdb_password": { "value": { "secret": $db_ccdb_password } },
      ".properties.system_database.external.account_username": { "value": $db_accountdb_username },
      ".properties.system_database.external.account_password": { "value": { "secret": $db_accountdb_password } },
      ".properties.system_database.external.networkpolicyserver_username": { "value": $db_networkpolicyserverdb_username },
      ".properties.system_database.external.networkpolicyserver_password": { "value": { "secret": $db_networkpolicyserverdb_password } },
      ".properties.system_database.external.nfsvolume_username": { "value": $db_nfsvolumedb_username },
      ".properties.system_database.external.nfsvolume_password": { "value": { "secret": $db_nfsvolumedb_password } },
      ".properties.system_database.external.locket_username": { "value": $db_locket_username },
      ".properties.system_database.external.locket_password": { "value": { "secret": $db_locket_password } },
      ".properties.system_database.external.silk_username": { "value": $db_silk_username },
      ".properties.system_database.external.silk_password": { "value": { "secret": $db_silk_password } },
      ".properties.uaa_database": { "value": "external" },
      ".properties.uaa_database.external.host": { "value": $db_host },
      ".properties.uaa_database.external.port": { "value": "3306" },
      ".properties.uaa_database.external.uaa_username": { "value": $db_uaa_username },
      ".properties.uaa_database.external.uaa_password": { "value": { "secret": $db_uaa_password } },
      ".cloud_controller.system_domain": { "value": "sys.\($pcf_ert_domain)" },
      ".cloud_controller.apps_domain": { "value": "cfapps.\($pcf_ert_domain)" },
      ".cloud_controller.allow_app_ssh_access": { "value": true },
      ".cloud_controller.security_event_logging_enabled": { "value": true },
      ".router.disable_insecure_cookies": { "value": false },
      ".push-apps-manager.company_name": { "value": "pcf-\($iaas)" },
      ".mysql_monitor.recipient_email": { "value" : $mysql_monitor_recipient_email }
    }

    +

    # logger_endpoint_port
    if $iaas == "aws" then
      {
        ".properties.logger_endpoint_port": { "value": 4443 }
      }
    else
      .
    end

    +

    # Blobstore

    if $iaas == "aws" then
      {
        ".properties.system_blobstore": { "value": "external" },
        ".properties.system_blobstore.external.buildpacks_bucket": { "value": "\($terraform_prefix)-buildpacks" },
        ".properties.system_blobstore.external.droplets_bucket": { "value": "\($terraform_prefix)-droplets" },
        ".properties.system_blobstore.external.packages_bucket": { "value": "\($terraform_prefix)-packages" },
        ".properties.system_blobstore.external.resources_bucket": { "value": "\($terraform_prefix)-resources" },
        ".properties.system_blobstore.external.access_key": { "value": $aws_access_key },
        ".properties.system_blobstore.external.secret_key": { "value": { "secret": $aws_secret_key } },
        ".properties.system_blobstore.external.signature_version.value": { "value": "2" },
        ".properties.system_blobstore.external.region": { "value": $aws_region },
        ".properties.system_blobstore.external.endpoint": { "value": $s3_endpoint }
      }
    elif $iaas == "gcp" then
      {
        ".properties.system_blobstore": { "value": "external_gcs" },
        ".properties.system_blobstore.external_gcs.buildpacks_bucket": { "value": "\($terraform_prefix)-buildpacks" },
        ".properties.system_blobstore.external_gcs.droplets_bucket": { "value": "\($terraform_prefix)-droplets" },
        ".properties.system_blobstore.external_gcs.packages_bucket": { "value": "\($terraform_prefix)-packages" },
        ".properties.system_blobstore.external_gcs.resources_bucket": { "value": "\($terraform_prefix)-resources" },
        ".properties.system_blobstore.external_gcs.access_key": { "value": $gcp_storage_access_key },
        ".properties.system_blobstore.external_gcs.secret_key": { "value": { "secret": $gcp_storage_secret_key } }
      }
    else
      .
    end

    +

    # MySQL Backups

    if $mysql_backups == "scp" then
      {
        ".properties.mysql_backups": {"value": $mysql_backups},
        ".properties.mysql_backups.scp.server": {"value": $mysql_backups_scp_server},
        ".properties.mysql_backups.scp.port": {"value": $mysql_backups_scp_port},
        ".properties.mysql_backups.scp.user": {"value": $mysql_backups_scp_user},
        ".properties.mysql_backups.scp.key": {"value": $mysql_backups_scp_key},
        ".properties.mysql_backups.scp.destination": {"value": $mysql_backups_scp_destination},
        ".properties.mysql_backups.scp.cron_schedule": {"value": $mysql_backups_scp_cron_schedule}
      }
    elif $mysql_backups == "s3" then
      {
        ".properties.mysql_backups": {"value": $mysql_backups},
        ".properties.mysql_backups.s3.endpoint_url": {"value": $mysql_backups_s3_endpoint_url},
        ".properties.mysql_backups.s3.bucket_name": {"value": $mysql_backups_s3_bucket_name},
        ".properties.mysql_backups.s3.bucket_path": {"value": $mysql_backups_s3_bucket_path},
        ".properties.mysql_backups.s3.access_key_id": {"value": $mysql_backups_s3_access_key_id},
        ".properties.mysql_backups.s3.secret_access_key": {"value": { "secret": $mysql_backups_s3_secret_access_key}},
        ".properties.mysql_backups.s3.cron_schedule": {"value": $mysql_backups_s3_cron_schedule}
      }
    else
      {
        ".properties.mysql_backups": {"value": "disable"}
      }
    end

    +

    # SSL Termination
    {
      ".properties.networking_poe_ssl_cert": {
        "value": {
          "cert_pem": $cert_pem,
          "private_key_pem": $private_key_pem
        }
      }
    }

    +

    # HAProxy Forward TLS
    if $haproxy_forward_tls == "enable" then
      {
        ".properties.haproxy_forward_tls": {
          "value": "enable"
        },
        ".properties.haproxy_forward_tls.enable.backend_ca": {
          "value": $haproxy_backend_ca
        }
      }
    else
      {
        ".properties.haproxy_forward_tls": {
          "value": "disable"
        }
      }
    end

    +

    {
      ".properties.routing_disable_http": {
        "value": $routing_disable_http
      }
    }

    +

    # TLS Cipher Suites
    {
      ".properties.gorouter_ssl_ciphers": {
        "value": $router_tls_ciphers
      },
      ".properties.haproxy_ssl_ciphers": {
        "value": $haproxy_tls_ciphers
      }
    }
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
