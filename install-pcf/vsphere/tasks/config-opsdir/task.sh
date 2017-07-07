#!/bin/bash

set -eu

iaas_configuration=$(cat <<-EOF
{
  "vcenter_host": "$VCENTER_HOST",
  "vcenter_username": "$VCENTER_USR",
  "vcenter_password": "$VCENTER_PWD",
  "datacenter": "$VCENTER_DATA_CENTER",
  "disk_type": "$VCENTER_DISK_TYPE",
  "ephemeral_datastores_string": "$EPHEMERAL_STORAGE_NAMES",
  "persistent_datastores_string": "$PERSISTENT_STORAGE_NAMES",
  "bosh_vm_folder": "$BOSH_VM_FOLDER",
  "bosh_template_folder": "$BOSH_TEMPLATE_FOLDER",
  "bosh_disk_path": "$BOSH_DISK_PATH",
  "ssl_verification_enabled": false,
  "nsx_networking_enabled": $NSX_NETWORKING_ENABLED,
  "nsx_address": "$NSX_ADDRESS",
  "nsx_username": "$NSX_USERNAME",
  "nsx_password": "$NSX_PASSWORD",
  "nsx_ca_certificate": "$NSX_CA_CERTIFICATE"
}
EOF
)

az_configuration=$(cat <<-EOF
{
  "availability_zones": [
    {
      "name": "$AZ_1",
      "cluster": "$AZ_1_CLUSTER_NAME",
      "resource_pool": "$AZ_1_RP_NAME"
    },
    {
      "name": "$AZ_2",
      "cluster": "$AZ_2_CLUSTER_NAME",
      "resource_pool": "$AZ_2_RP_NAME"
    },
    {
      "name": "$AZ_3",
      "cluster": "$AZ_3_CLUSTER_NAME",
      "resource_pool": "$AZ_3_RP_NAME"
    }
  ]
}
EOF
)

network_configuration=$(
  echo '{}' |
  jq \
    --argjson icmp_checks_enabled $ICMP_CHECKS_ENABLED \
    --arg infra_network_name "$INFRA_NETWORK_NAME" \
    --arg infra_vcenter_network "$INFRA_VCENTER_NETWORK" \
    --arg infra_network_cidr "$INFRA_NW_CIDR" \
    --arg infra_reserved_ip_ranges "$INFRA_EXCLUDED_RANGE" \
    --arg infra_dns "$INFRA_NW_DNS" \
    --arg infra_gateway "$INFRA_NW_GATEWAY" \
    --arg infra_availability_zones "$INFRA_NW_AZS" \
    --arg deployment_network_name "$DEPLOYMENT_NETWORK_NAME" \
    --arg deployment_vcenter_network "$DEPLOYMENT_VCENTER_NETWORK" \
    --arg deployment_network_cidr "$DEPLOYMENT_NW_CIDR" \
    --arg deployment_reserved_ip_ranges "$DEPLOYMENT_EXCLUDED_RANGE" \
    --arg deployment_dns "$DEPLOYMENT_NW_DNS" \
    --arg deployment_gateway "$DEPLOYMENT_NW_GATEWAY" \
    --arg deployment_availability_zones "$DEPLOYMENT_NW_AZS" \
    --argjson services_network_is_service_network $IS_SERVICE_NETWORK \
    --arg services_network_name "$SERVICES_NETWORK_NAME" \
    --arg services_vcenter_network "$SERVICES_VCENTER_NETWORK" \
    --arg services_network_cidr "$SERVICES_NW_CIDR" \
    --arg services_reserved_ip_ranges "$SERVICES_EXCLUDED_RANGE" \
    --arg services_dns "$SERVICES_NW_DNS" \
    --arg services_gateway "$SERVICES_NW_GATEWAY" \
    --arg services_availability_zones "$SERVICES_NW_AZS" \
    --arg dynamic_services_network_name "$DYNAMIC_SERVICES_NETWORK_NAME" \
    --arg dynamic_services_vcenter_network "$DYNAMIC_SERVICES_VCENTER_NETWORK" \
    --arg dynamic_services_network_cidr "$DYNAMIC_SERVICES_NW_CIDR" \
    --arg dynamic_services_reserved_ip_ranges "$DYNAMIC_SERVICES_EXCLUDED_RANGE" \
    --arg dynamic_services_dns "$DYNAMIC_SERVICES_NW_DNS" \
    --arg dynamic_services_gateway "$DYNAMIC_SERVICES_NW_GATEWAY" \
    --arg dynamic_services_availability_zones "$DYNAMIC_SERVICES_NW_AZS" \
    '. +
    {
      "icmp_checks_enabled": $icmp_checks_enabled,
      "networks": [
        {
          "name": $infra_network_name,
          "service_network": false,
          "subnets": [
            {
              "iaas_identifier": $infra_vcenter_network,
              "cidr": $infra_network_cidr,
              "reserved_ip_ranges": $infra_reserved_ip_ranges,
              "dns": $infra_dns,
              "gateway": $infra_gateway,
              "availability_zones": ($infra_availability_zones | split(","))
            }
          ]
        },
        {
          "name": $deployment_network_name,
          "service_network": false,
          "subnets": [
            {
              "iaas_identifier": $deployment_vcenter_network,
              "cidr": $deployment_network_cidr,
              "reserved_ip_ranges": $deployment_reserved_ip_ranges,
              "dns": $deployment_dns,
              "gateway": $deployment_gateway,
              "availability_zones": ($deployment_availability_zones | split(","))
            }
          ]
        },
        {
          "name": $services_network_name,
          "service_network": $services_network_is_service_network,
          "subnets": [
            {
              "iaas_identifier": $services_vcenter_network,
              "cidr": $services_network_cidr,
              "reserved_ip_ranges": $services_reserved_ip_ranges,
              "dns": $services_dns,
              "gateway": $services_gateway,
              "availability_zones": ($services_availability_zones | split(","))
            }
          ]
        },
        {
          "name": $dynamic_services_network_name,
          "service_network": true,
          "subnets": [
            {
              "iaas_identifier": $dynamic_services_vcenter_network,
              "cidr": $dynamic_services_network_cidr,
              "reserved_ip_ranges": $dynamic_services_reserved_ip_ranges,
              "dns": $dynamic_services_dns,
              "gateway": $dynamic_services_gateway,
              "availability_zones": ($dynamic_services_availability_zones | split(","))
            }
          ]
        }
      ]
    }'
)

director_config=$(cat <<-EOF
{
  "ntp_servers_string": "$NTP_SERVERS",
  "resurrector_enabled": $ENABLE_VM_RESURRECTOR,
  "max_threads": $MAX_THREADS,
  "database_type": "internal",
  "blobstore_type": "local",
  "director_hostname": "$OPS_DIR_HOSTNAME"
}
EOF
)

security_configuration=$(
  echo '{}' |
  jq \
    --arg trusted_certificates "$TRUSTED_CERTIFICATES" \
    '. +
    {
      "trusted_certificates": $trusted_certificates,
      "vm_password_type": "generate"
    }'
)

network_assignment=$(
echo '{}' |
jq \
  --arg infra_availability_zones "$INFRA_NW_AZS" \
  --arg network "$INFRA_NETWORK_NAME" \
  '. +
  {
    "singleton_availability_zone": ($infra_availability_zones | split(",") | .[0]),
    "network": $network
  }'
)

echo "Configuring IaaS and Director..."
om-linux \
  --target https://$OPS_MGR_HOST \
  --skip-ssl-validation \
  --username $OPS_MGR_USR \
  --password $OPS_MGR_PWD \
  configure-bosh \
  --iaas-configuration "$iaas_configuration" \
  --director-configuration "$director_config"

om-linux -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD \
  curl -p "/api/v0/staged/director/availability_zones" \
  -x PUT -d "$az_configuration"

om-linux \
  --target https://$OPS_MGR_HOST \
  --skip-ssl-validation \
  --username $OPS_MGR_USR \
  --password $OPS_MGR_PWD \
  configure-bosh \
  --networks-configuration "$network_configuration" \
  --network-assignment "$network_assignment" \
  --security-configuration "$security_configuration"
