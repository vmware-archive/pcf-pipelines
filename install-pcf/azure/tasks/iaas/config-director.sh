#!/bin/bash
set -eu

echo "=============================================================================================="
echo "Configuring Director @ https://${OPSMAN_DOMAIN_OR_IP_ADDRESS} ..."
echo "=============================================================================================="

ENV_SHORT_NAME="$(echo ${AZURE_TERRAFORM_PREFIX} | tr -d "-" | tr -d "_" | tr -d "[0-9]")"
ENV_SHORT_NAME="$(echo ${ENV_SHORT_NAME:0:10})"

iaas_configuration=$(
  jq -n \
    --arg subscription_id "${AZURE_SUBSCRIPTION_ID}" \
    --arg tenant_id "${AZURE_TENANT_ID}" \
    --arg client_id "${AZURE_CLIENT_ID}" \
    --arg client_secret "${AZURE_CLIENT_SECRET}" \
    --arg resource_group_name "${AZURE_TERRAFORM_PREFIX}-pcf-resource-group" \
    --arg bosh_storage_account_name "${ENV_SHORT_NAME}director" \
    --arg deployments_storage_account_name "*boshvms*" \
    --arg default_security_group "${AZURE_TERRAFORM_PREFIX}-bosh-deployed-vms-security-group" \
    --arg ssh_public_key "${PCF_SSH_KEY_PUB}" \
    --arg ssh_private_key "${PCF_SSH_KEY_PRIV}" \
    --arg cloud_storage_type "managed_disks" \
    --arg storage_account_type "Premium_LRS" \
    --arg environment "AzureCloud" \
    '{
      "subscription_id": $subscription_id,
      "tenant_id": $tenant_id,
      "client_id": $client_id,
      "client_secret": $client_secret,
      "resource_group_name": $resource_group_name,
      "bosh_storage_account_name": $bosh_storage_account_name,
      "default_security_group": $default_security_group,
      "ssh_public_key": $ssh_public_key,
      "ssh_private_key": $ssh_private_key,
      "cloud_storage_type": $cloud_storage_type,
      "storage_account_type": $storage_account_type,
      "environment": $environment
    }'
)

director_configuration=$(
  jq -n \
    '{
      "ntp_servers_string": "0.pool.ntp.org",
      "metrics_ip": "",
      "resurrector_enabled": true,
      "post_deploy_enabled": false,
      "bosh_recreate_on_next_deploy": false,
      "retry_bosh_deploys": true,
      "hm_pager_duty_options": {
        "enabled": false,
      },
      "hm_emailer_options": {
        "enabled": false,
      },
      "blobstore_type": "local",
      "database_type": "internal"
    }'
)

cp terraform-state/terraform.tfstate ./

VIRTUAL_NETWORK=$(terraform output network_name)

MANAGEMENT_SUBNET=$(terraform output management_subnet_name)
MANAGEMENT_CIDRS=$(terraform output management_subnet_cidrs)
MANAGEMENT_GATEWAY=$(terraform output management_subnet_gateway)

PAS_SUBNET=$(terraform output pas_subnet_name)
PAS_CIDRS=$(terraform output pas_subnet_cidrs)
PAS_GATEWAY=$(terraform output pas_subnet_gateway)

SERVICES_SUBNET=$(terraform output services_subnet_name)
SERVICES_CIDRS=$(terraform output services_subnet_cidrs)
SERVICES_GATEWAY=$(terraform output services_subnet_gateway)

DYNAMIC_SERVICES_SUBNET=$(terraform output dynamic_services_subnet_name)
DYNAMIC_SERVICES_CIDRS=$(terraform output dynamic_services_subnet_cidrs)
DYNAMIC_SERVICES_GATEWAY=$(terraform output dynamic_services_subnet_gateway)

networks_configuration=$(
  jq -n \
    --arg infra_subnet_iaas "${VIRTUAL_NETWORK}/${MANAGEMENT_SUBNET}" \
    --arg infra_subnet_cidr "${MANAGEMENT_CIDRS}" \
    --arg infra_subnet_reserved "${AZURE_TERRAFORM_SUBNET_INFRA_RESERVED}" \
    --arg infra_subnet_dns "${AZURE_TERRAFORM_SUBNET_INFRA_DNS}" \
    --arg infra_subnet_gateway "${MANAGEMENT_GATEWAY}" \
    --arg ert_subnet_iaas "${VIRTUAL_NETWORK}/${PAS_SUBNET}" \
    --arg ert_subnet_cidr "${PAS_CIDRS}" \
    --arg ert_subnet_reserved "${AZURE_TERRAFORM_SUBNET_PAS_RESERVED}" \
    --arg ert_subnet_dns "${AZURE_TERRAFORM_SUBNET_PAS_DNS}" \
    --arg ert_subnet_gateway "${PAS_GATEWAY}" \
    --arg services_subnet_iaas "${VIRTUAL_NETWORK}/${SERVICES_SUBNET}" \
    --arg services_subnet_cidr "${SERVICES_CIDRS}" \
    --arg services_subnet_reserved "${AZURE_TERRAFORM_SUBNET_SERVICES_RESERVED}" \
    --arg services_subnet_dns "${AZURE_TERRAFORM_SUBNET_SERVICES_DNS}" \
    --arg services_subnet_gateway "${SERVICES_GATEWAY}" \
    --arg dynamic_services_subnet_iaas "${VIRTUAL_NETWORK}/${DYNAMIC_SERVICES_SUBNET}" \
    --arg dynamic_services_subnet_cidr "${DYNAMIC_SERVICES_CIDRS}" \
    --arg dynamic_services_subnet_reserved "${AZURE_TERRAFORM_SUBNET_DYNAMIC_SERVICES_RESERVED}" \
    --arg dynamic_services_subnet_dns "${AZURE_TERRAFORM_SUBNET_DYNAMIC_SERVICES_DNS}" \
    --arg dynamic_services_subnet_gateway "${DYNAMIC_SERVICES_GATEWAY}" \
    '{
      "icmp_checks_enabled": false,
      "networks": [
        {
          "name": "infrastructure",
          "service_network": false,
          "subnets": [
            {
              "iaas_identifier": $infra_subnet_iaas,
              "cidr": $infra_subnet_cidr,
              "reserved_ip_ranges": $infra_subnet_reserved,
              "dns": $infra_subnet_dns,
              "gateway": $infra_subnet_gateway,
            }
          ]
        },
        {
          "name": "ert",
          "service_network": false,
          "subnets": [
            {
              "iaas_identifier": $ert_subnet_iaas,
              "cidr": $ert_subnet_cidr,
              "reserved_ip_ranges": $ert_subnet_reserved,
              "dns": $ert_subnet_dns,
              "gateway": $ert_subnet_gateway,
            }
          ]
        },
        {
          "name": "services-1",
          "service_network": false,
          "subnets": [
            {
              "iaas_identifier": $services_subnet_iaas,
              "cidr": $services_subnet_cidr,
              "reserved_ip_ranges": $services_subnet_reserved,
              "dns": $services_subnet_dns,
              "gateway": $services_subnet_gateway
            }
          ]
        },
        {
          "name": "dynamic-services",
          "service_network": true,
          "subnets": [
            {
              "iaas_identifier": $dynamic_services_subnet_iaas,
              "cidr": $dynamic_services_subnet_cidr,
              "reserved_ip_ranges": $dynamic_services_subnet_reserved,
              "dns": $dynamic_services_subnet_dns,
              "gateway": $dynamic_services_subnet_gateway,
            }
          ]
        }
      ]
    }'
)

network_assignment=$(
  jq -n \
    '{
      "network": {
        "name": "infrastructure"
      }
    }'
)

security_configuration=$(
  jq -n \
    --arg trusted_cert "${TRUSTED_CERTIFICATES}" \
    '{
      "trusted_certificates": $trusted_cert,
      "generate_vm_passwords": true
    }'
)

om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username "$PCF_OPSMAN_ADMIN" \
  --password "$PCF_OPSMAN_ADMIN_PASSWORD" \
  configure-director \
  --iaas-configuration "${iaas_configuration}" \
  --director-configuration "${director_configuration}" \
  --networks-configuration "${networks_configuration}" \
  --network-assignment "${network_assignment}" \
  --security-configuration "${security_configuration}"
