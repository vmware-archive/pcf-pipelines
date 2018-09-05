#!/bin/bash

set -euo pipefail

export OPSMAN_DOMAIN_OR_IP_ADDRESS="opsman.$PCF_ERT_DOMAIN"

source pcf-pipelines/functions/generate_cert.sh

declare networking_poe_ssl_certs_json

saml_domains=(
  "*.${SYSTEM_DOMAIN}"
  "*.login.${SYSTEM_DOMAIN}"
  "*.uaa.${SYSTEM_DOMAIN}"
)

saml_certificates=$(generate_cert "${saml_domains[*]}")
saml_cert_pem=`echo $saml_certificates | jq --raw-output '.certificate'`
saml_key_pem=`echo $saml_certificates | jq --raw-output '.key'`

function isPopulated() {
    local true=0
    local false=1
    local envVar="${1}"

    if [[ "${envVar}" == "" ]]; then
        return ${false}
    elif [[ "${envVar}" == null ]]; then
        return ${false}
    else
        return ${true}
    fi
}

function formatCredhubEncryptionKeysJson() {
    local credhub_encryption_key_name1="${1}"
    local credhub_encryption_key_secret1=${2//$'\n'/'\n'}
    local credhub_primary_encryption_name="${3}"
    credhub_encryption_keys_json="{
            \"name\": \"$credhub_encryption_key_name1\",
            \"key\":{
                \"secret\": \"$credhub_encryption_key_secret1\"
             }"
    if [[ "${credhub_primary_encryption_name}" == $credhub_encryption_key_name1 ]]; then
        credhub_encryption_keys_json="$credhub_encryption_keys_json, \"primary\": true}"
    else
        credhub_encryption_keys_json="$credhub_encryption_keys_json}"
    fi
    echo "$credhub_encryption_keys_json"
}

credhub_encryption_keys_json=$(formatCredhubEncryptionKeysJson "${CREDUB_ENCRYPTION_KEY_NAME1}" "${CREDUB_ENCRYPTION_KEY_SECRET1}" "${CREDHUB_PRIMARY_ENCRYPTION_NAME}")
if isPopulated "${CREDUB_ENCRYPTION_KEY_NAME2}"; then
    credhub_encryption_keys_json2=$(formatCredhubEncryptionKeysJson "${CREDUB_ENCRYPTION_KEY_NAME2}" "${CREDUB_ENCRYPTION_KEY_SECRET2}" "${CREDHUB_PRIMARY_ENCRYPTION_NAME}")
    credhub_encryption_keys_json="$credhub_encryption_keys_json,$credhub_encryption_keys_json2"
fi
if isPopulated "${CREDUB_ENCRYPTION_KEY_NAME3}"; then
    credhub_encryption_keys_json3=$(formatCredhubEncryptionKeysJson "${CREDUB_ENCRYPTION_KEY_NAME3}" "${CREDUB_ENCRYPTION_KEY_SECRET3}" "${CREDHUB_PRIMARY_ENCRYPTION_NAME}")
    credhub_encryption_keys_json="$credhub_encryption_keys_json,$credhub_encryption_keys_json3"
fi
credhub_encryption_keys_json="[$credhub_encryption_keys_json]"

if [[ "${pcf_iaas}" == "aws" ]]; then
  if [[ ${POE_SSL_NAME1} == "" || ${POE_SSL_NAME1} == "null" ]]; then
    domains=(
        "*.${SYSTEM_DOMAIN}"
        "*.${APPS_DOMAIN}"
        "*.login.${SYSTEM_DOMAIN}"
        "*.uaa.${SYSTEM_DOMAIN}"
    )

    certificate=$(generate_cert "${domains[*]}")
    pcf_ert_ssl_cert=`echo $certificate | jq '.certificate'`
    pcf_ert_ssl_key=`echo $certificate | jq '.key'`
    networking_poe_ssl_certs_json="[
      {
        \"name\": \"Certificate 1\",
        \"certificate\": {
          \"cert_pem\": $pcf_ert_ssl_cert,
          \"private_key_pem\": $pcf_ert_ssl_key
        }
      }
    ]"
  else
    cert=${POE_SSL_CERT1//$'\n'/'\n'}
    key=${POE_SSL_KEY1//$'\n'/'\n'}
    networking_poe_ssl_certs_json="[{
      \"name\": \"$POE_SSL_NAME1\",
      \"certificate\": {
        \"cert_pem\": \"$cert\",
        \"private_key_pem\": \"$key\"
      }
    }]"
  fi

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
    pcf_ert_ssl_cert="$(terraform output -json ert_certificate | jq .value)"
    pcf_ert_ssl_key="$(terraform output -json ert_certificate_key | jq .value)"
  cd -

  if [ -z "$db_host" ]; then
    echo Failed to get SQL instance IP from Terraform state file
    exit 1
  fi
  networking_poe_ssl_certs_json="[
    {
      \"name\": \"Certificate 1\",
      \"certificate\": {
        \"cert_pem\": $pcf_ert_ssl_cert,
        \"private_key_pem\": $pcf_ert_ssl_key
      }
    }
  ]"
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
    --argjson internet_connected $INTERNET_CONNECTED \
    '
    {
      "backup_restore": {"internet_connected": $internet_connected},
      "clock_global": {"internet_connected": $internet_connected},
      "cloud_controller": {"internet_connected": $internet_connected},
      "cloud_controller_worker": {"internet_connected": $internet_connected},
      "consul_server": {"internet_connected": $internet_connected},
      "credhub": {"internet_connected": $internet_connected},
      "diego_brain": {"internet_connected": $internet_connected},
      "diego_cell": {"internet_connected": $internet_connected},
      "diego_database": {"internet_connected": $internet_connected},
      "doppler": {"internet_connected": $internet_connected},
      "ha_proxy": {"internet_connected": $internet_connected},
      "loggregator_trafficcontroller": {"internet_connected": $internet_connected},
      "mysql": {"instances": 0, "internet_connected": $internet_connected},
      "mysql_monitor": {"instances": 0, "internet_connected": $internet_connected},
      "mysql_proxy": {"instances": 0, "internet_connected": $internet_connected},
      "nats": {"internet_connected": $internet_connected},
      "nfs_server": {"internet_connected": $internet_connected},
      "router": {"internet_connected": $internet_connected},
      "syslog_adapter": {"internet_connected": $internet_connected},
      "syslog_scheduler": {"internet_connected": $internet_connected},
      "tcp_router": {"internet_connected": $internet_connected},
      "uaa": {"internet_connected": $internet_connected}
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
    --arg saml_cert_pem "$saml_cert_pem" \
    --arg saml_key_pem "$saml_key_pem" \
    --arg haproxy_forward_tls "$HAPROXY_FORWARD_TLS" \
    --arg haproxy_backend_ca "$HAPROXY_BACKEND_CA" \
    --arg router_tls_ciphers "$ROUTER_TLS_CIPHERS" \
    --arg haproxy_tls_ciphers "$HAPROXY_TLS_CIPHERS" \
    --arg frontend_idle_timeout "$FRONTEND_IDLE_TIMEOUT" \
    --arg routing_disable_http "$routing_disable_http" \
    --arg routing_custom_ca_certificates "$ROUTING_CUSTOM_CA_CERTIFICATES" \
    --arg routing_tls_termination $ROUTING_TLS_TERMINATION \
    --arg security_acknowledgement "$SECURITY_ACKNOWLEDGEMENT" \
    --arg iaas $pcf_iaas \
    --arg pcf_ert_domain "$PCF_ERT_DOMAIN" \
    --arg system_domain "$SYSTEM_DOMAIN"\
    --arg apps_domain "$APPS_DOMAIN" \
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
    --argjson credhub_encryption_keys "$credhub_encryption_keys_json" \
    --argjson networking_poe_ssl_certs "$networking_poe_ssl_certs_json" \
    --arg container_networking_nw_cidr "$CONTAINER_NETWORKING_NW_CIDR" \
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
      ".properties.container_networking_interface_plugin.silk.network_cidr": { "value": $container_networking_nw_cidr },
      ".properties.route_services.enable.ignore_ssl_cert_verification": { "value": true },
      ".properties.security_acknowledgement": { "value": $security_acknowledgement },
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
      ".properties.push_apps_manager_company_name": { "value": "pcf-\($iaas)" },
      ".cloud_controller.system_domain": { "value": $system_domain },
      ".cloud_controller.apps_domain": { "value": $apps_domain },
      ".cloud_controller.allow_app_ssh_access": { "value": true },
      ".cloud_controller.security_event_logging_enabled": { "value": true },
      ".router.disable_insecure_cookies": { "value": false },
      ".router.frontend_idle_timeout": { "value": $frontend_idle_timeout },
      ".mysql_monitor.recipient_email": { "value" : $mysql_monitor_recipient_email }
    }

    +

    # Credhub encryption keys
    {
      ".properties.credhub_key_encryption_passwords": {
        "value": $credhub_encryption_keys
      }
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
        ".properties.system_blobstore.external.signature_version": { "value": "4" },
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

    # SSL Termination
    {
      ".properties.networking_poe_ssl_certs": {
        "value": $networking_poe_ssl_certs
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

    if $routing_custom_ca_certificates == "" then
      .
    else
      {
        ".properties.routing_custom_ca_certificates": {
          "value": $routing_custom_ca_certificates
        }
      }
    end

    +

    {
      ".properties.routing_tls_termination": {
        "value": $routing_tls_termination
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
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name cf \
  --product-properties "$cf_properties" \
  --product-network "$cf_network" \
  --product-resources "$cf_resources"
