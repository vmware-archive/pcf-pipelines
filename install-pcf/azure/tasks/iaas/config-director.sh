#!/bin/bash
set -e

echo "=============================================================================================="
echo "Configuring Director @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="

# Set JSON Config Template and inster Concourse Parameter Values
json_file_path="pcf-pipelines/install-pcf/azure/json-opsman/${azure_pcf_terraform_template}"
json_file_template="${json_file_path}/opsman-template.json"
json_file="${json_file_path}/opsman.json"

resgroup_lookup_net=${azure_terraform_prefix}
resgroup_lookup_pcf=${azure_terraform_prefix}
infrastructure_subnet="${azure_terraform_prefix}-virtual-network/${azure_terraform_prefix}-opsman-and-director-subnet"
ert_subnet="${azure_terraform_prefix}-virtual-network/${azure_terraform_prefix}-ert-subnet"
services1_subnet="${azure_terraform_prefix}-virtual-network/${azure_terraform_prefix}-services-01-subnet"
dynamic_services_subnet="${azure_terraform_prefix}-virtual-network/${azure_terraform_prefix}-dynamic-services-subnet"

cp ${json_file_template} ${json_file}

perl -pi -e "s|{{infra_subnet_iaas}}|${infrastructure_subnet}|g" ${json_file}
perl -pi -e "s|{{infra_subnet_cidr}}|${azure_terraform_subnet_infra_cidr}|g" ${json_file}
perl -pi -e "s|{{infra_subnet_reserved}}|${azure_terraform_subnet_infra_reserved}|g" ${json_file}
perl -pi -e "s|{{infra_subnet_dns}}|${azure_terraform_subnet_infra_dns}|g" ${json_file}
perl -pi -e "s|{{infra_subnet_gateway}}|${azure_terraform_subnet_infra_gateway}|g" ${json_file}
perl -pi -e "s|{{ert_subnet_iaas}}|${ert_subnet}|g" ${json_file}
perl -pi -e "s|{{ert_subnet_cidr}}|${azure_terraform_subnet_ert_cidr}|g" ${json_file}
perl -pi -e "s|{{ert_subnet_reserved}}|${azure_terraform_subnet_ert_reserved}|g" ${json_file}
perl -pi -e "s|{{ert_subnet_dns}}|${azure_terraform_subnet_ert_dns}|g" ${json_file}
perl -pi -e "s|{{ert_subnet_gateway}}|${azure_terraform_subnet_ert_gateway}|g" ${json_file}
perl -pi -e "s|{{services1_subnet_iaas}}|${services1_subnet}|g" ${json_file}
perl -pi -e "s|{{services1_subnet_cidr}}|${azure_terraform_subnet_services1_cidr}|g" ${json_file}
perl -pi -e "s|{{services1_subnet_reserved}}|${azure_terraform_subnet_services1_reserved}|g" ${json_file}
perl -pi -e "s|{{services1_subnet_dns}}|${azure_terraform_subnet_services1_dns}|g" ${json_file}
perl -pi -e "s|{{services1_subnet_gateway}}|${azure_terraform_subnet_services1_gateway}|g" ${json_file}
perl -pi -e "s|{{dynamic_services_subnet_iaas}}|${dynamic_services_subnet}|g" ${json_file}
perl -pi -e "s|{{dynamic_services_subnet_cidr}}|${azure_terraform_subnet_dynamic_services_cidr}|g" ${json_file}
perl -pi -e "s|{{dynamic_services_subnet_reserved}}|${azure_terraform_subnet_dynamic_services_reserved}|g" ${json_file}
perl -pi -e "s|{{dynamic_services_subnet_dns}}|${azure_terraform_subnet_dynamic_services_dns}|g" ${json_file}
perl -pi -e "s|{{dynamic_services_subnet_gateway}}|${azure_terraform_subnet_dynamic_services_gateway}|g" ${json_file}




# Exec bash scripts to config Opsman Director Tile
./pcf-pipelines/install-pcf/azure/json-opsman/config-director-json.sh azure director
