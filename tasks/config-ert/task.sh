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

saml_cert_domains=(
  "*.${SYSTEM_DOMAIN}"
  "*.login.${SYSTEM_DOMAIN}"
  "*.uaa.${SYSTEM_DOMAIN}"
)

saml_certificates=$(generate_cert "${saml_cert_domains[*]}")
saml_cert_pem=$(echo $saml_certificates | jq --raw-output '.certificate')
saml_key_pem=$(echo $saml_certificates | jq --raw-output '.key')

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $script_dir/load_cf_properties.sh

cf_network=$(
  echo '{}' |
  jq \
    --arg network_name "$NETWORK_NAME" \
    --arg other_azs "$DEPLOYMENT_NW_AZS" \
    --arg singleton_az "$ERT_SINGLETON_JOB_AZ" \
    '
    . +
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
  set +e
  read -d'%' -r input <<EOF
  {
    "backup-prepare": $BACKUP_PREPARE_INSTANCES,
    "ccdb": $CCDB_INSTANCES,
    "clock_global": $CLOCK_GLOBAL_INSTANCES,
    "cloud_controller": $CLOUD_CONTROLLER_INSTANCES,
    "cloud_controller_worker": $CLOUD_CONTROLLER_WORKER_INSTANCES,
    "consul_server": $CONSUL_SERVER_INSTANCES,
    "diego_brain": $DIEGO_BRAIN_INSTANCES,
    "diego_cell": $DIEGO_CELL_INSTANCES,
    "diego_database": $DIEGO_DATABASE_INSTANCES,
    "doppler": $DOPPLER_INSTANCES,
    "etcd_tls_server": $ETCD_TLS_SERVER_INSTANCES,
    "ha_proxy": $HA_PROXY_INSTANCES,
    "loggregator_trafficcontroller": $LOGGREGATOR_TC_INSTANCES,
    "mysql": $MYSQL_INSTANCES,
    "mysql_monitor": $MYSQL_MONITOR_INSTANCES,
    "mysql_proxy": $MYSQL_PROXY_INSTANCES,
    "nats": $NATS_INSTANCES,
    "nfs_server": $NFS_SERVER_INSTANCES,
    "router": $ROUTER_INSTANCES,
    "syslog_adapter": $SYSLOG_ADAPTER_INSTANCES,
    "syslog_scheduler": $SYSLOG_SCHEDULER_INSTANCES,
    "tcp_router": $TCP_ROUTER_INSTANCES,
    "uaa": $UAA_INSTANCES,
    "uaadb": $UAADB_INSTANCES
  }
  %
EOF
  set -e

  echo "$input" | jq \
    'map_values(. = .)'
)

om-linux \
  --target https://$OPS_MGR_HOST \
  --username $OPS_MGR_USR \
  --password $OPS_MGR_PWD \
  --skip-ssl-validation \
  configure-product \
  --product-name cf \
  --product-properties "$cf_properties" \
  --product-network "$cf_network" \
  --product-resources "$cf_resources"
