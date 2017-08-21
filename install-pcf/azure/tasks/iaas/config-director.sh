#!/bin/bash
set -eu

echo "=============================================================================================="
echo "Configuring Director @ https://${OPSMAN_DOMAIN_OR_IP_ADDRESS} ..."
echo "=============================================================================================="

# Set JSON Config Template and inster Concourse Parameter Values
JSON_FILE_PATH="pcf-pipelines/install-pcf/azure/json-opsman/${AZURE_PCF_TERRAFORM_TEMPLATE}"
JSON_FILE_TEMPLATE="${JSON_FILE_PATH}/opsman-template.json"
JSON_FILE="${JSON_FILE_PATH}/opsman.json"

RESGROUP_LOOKUP_NET=${AZURE_TERRAFORM_PREFIX}
RESGROUP_LOOKUP_PCF=${AZURE_TERRAFORM_PREFIX}
INFRASTRUCTURE_SUBNET="${AZURE_TERRAFORM_PREFIX}-virtual-network/${AZURE_TERRAFORM_PREFIX}-opsman-and-director-subnet"
ERT_SUBNET="${AZURE_TERRAFORM_PREFIX}-virtual-network/${AZURE_TERRAFORM_PREFIX}-ert-subnet"
SERVICES1_SUBNET="${AZURE_TERRAFORM_PREFIX}-virtual-network/${AZURE_TERRAFORM_PREFIX}-services-01-subnet"
DYNAMIC_SERVICES_SUBNET="${AZURE_TERRAFORM_PREFIX}-virtual-network/${AZURE_TERRAFORM_PREFIX}-dynamic-services-subnet"

cp ${JSON_FILE_TEMPLATE} ${JSON_FILE}

perl -pi -e "s|{{infra_subnet_iaas}}|${INFRASTRUCTURE_SUBNET}|g" ${JSON_FILE}
perl -pi -e "s|{{infra_subnet_cidr}}|${AZURE_TERRAFORM_SUBNET_INFRA_CIDR}|g" ${JSON_FILE}
perl -pi -e "s|{{infra_subnet_reserved}}|${AZURE_TERRAFORM_SUBNET_INFRA_RESERVED}|g" ${JSON_FILE}
perl -pi -e "s|{{infra_subnet_dns}}|${AZURE_TERRAFORM_SUBNET_INFRA_DNS}|g" ${JSON_FILE}
perl -pi -e "s|{{infra_subnet_gateway}}|${AZURE_TERRAFORM_SUBNET_INFRA_GATEWAY}|g" ${JSON_FILE}
perl -pi -e "s|{{ert_subnet_iaas}}|${ERT_SUBNET}|g" ${JSON_FILE}
perl -pi -e "s|{{ert_subnet_cidr}}|${AZURE_TERRAFORM_SUBNET_ERT_CIDR}|g" ${JSON_FILE}
perl -pi -e "s|{{ert_subnet_reserved}}|${AZURE_TERRAFORM_SUBNET_ERT_RESERVED}|g" ${JSON_FILE}
perl -pi -e "s|{{ert_subnet_dns}}|${AZURE_TERRAFORM_SUBNET_ERT_DNS}|g" ${JSON_FILE}
perl -pi -e "s|{{ert_subnet_gateway}}|${AZURE_TERRAFORM_SUBNET_ERT_GATEWAY}|g" ${JSON_FILE}
perl -pi -e "s|{{services1_subnet_iaas}}|${SERVICES1_SUBNET}|g" ${JSON_FILE}
perl -pi -e "s|{{services1_subnet_cidr}}|${AZURE_TERRAFORM_SUBNET_SERVICES1_CIDR}|g" ${JSON_FILE}
perl -pi -e "s|{{services1_subnet_reserved}}|${AZURE_TERRAFORM_SUBNET_SERVICES1_RESERVED}|g" ${JSON_FILE}
perl -pi -e "s|{{services1_subnet_dns}}|${AZURE_TERRAFORM_SUBNET_SERVICES1_DNS}|g" ${JSON_FILE}
perl -pi -e "s|{{services1_subnet_gateway}}|${AZURE_TERRAFORM_SUBNET_SERVICES1_GATEWAY}|g" ${JSON_FILE}
perl -pi -e "s|{{dynamic_services_subnet_iaas}}|${DYNAMIC_SERVICES_SUBNET}|g" ${JSON_FILE}
perl -pi -e "s|{{dynamic_services_subnet_cidr}}|${AZURE_TERRAFORM_SUBNET_DYNAMIC_SERVICES_CIDR}|g" ${JSON_FILE}
perl -pi -e "s|{{dynamic_services_subnet_reserved}}|${AZURE_TERRAFORM_SUBNET_DYNAMIC_SERVICES_RESERVED}|g" ${JSON_FILE}
perl -pi -e "s|{{dynamic_services_subnet_dns}}|${AZURE_TERRAFORM_SUBNET_DYNAMIC_SERVICES_DNS}|g" ${JSON_FILE}
perl -pi -e "s|{{dynamic_services_subnet_gateway}}|${AZURE_TERRAFORM_SUBNET_DYNAMIC_SERVICES_GATEWAY}|g" ${JSON_FILE}




# Exec bash scripts to config Opsman Director Tile
./pcf-pipelines/install-pcf/azure/json-opsman/config-director-json.sh azure director
