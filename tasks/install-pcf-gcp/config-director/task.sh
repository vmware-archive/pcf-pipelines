#!/bin/bash
set -e

cat > opsman.json <<EOF
[{
  "director_configuration": {
    "director_configuration[ntp_servers_string]": "0.pool.ntp.org",
    "director_configuration[metrics_ip]": "",
    "director_configuration[resurrector_enabled]": "1",
    "director_configuration[post_deploy_enabled]": "0",
    "director_configuration[bosh_recreate_on_next_deploy]": "0",
    "director_configuration[retry_bosh_deploys]": "1",
    "director_configuration[hm_pager_duty_options][enabled]": "0",
    "director_configuration[hm_emailer_options][enabled]": "0",
    "director_configuration[blobstore_type]": "local",
    "director_configuration[database_type]": "internal",
    "director_configuration[max_threads]": "",
    "director_configuration[director_hostname]": ""
  },
  "availability_zones": {
    "availability_zones": ["${gcp_zone_1}","${gcp_zone_2}","${gcp_zone_3}"],
    "pipeline_extension": "fn_form_gen_availability_zones"
  },
  "networks": {
    "infrastructure[icmp_checks_enabled]": "0",
    "network_collection[networks_attributes][0][guid]": "0",
    "network_collection[networks_attributes][0][name]": "infrastructure",
    "network_collection[networks_attributes][0][service_network]": "0",
    "network_collection[networks_attributes][0][subnets][0][iaas_identifier]": "${gcp_resource_prefix}-virt-net/${gcp_resource_prefix}-subnet-infrastructure-${gcp_region}/${gcp_region}",
    "network_collection[networks_attributes][0][subnets][0][cidr]": "192.168.101.0/26",
    "network_collection[networks_attributes][0][subnets][0][reserved_ip_ranges]": "192.168.101.1-192.168.101.9",
    "network_collection[networks_attributes][0][subnets][0][dns]": "192.168.101.1,8.8.8.8",
    "network_collection[networks_attributes][0][subnets][0][gateway]": "192.168.101.1",
    "network_collection[networks_attributes][0][subnets][0][availability_zone_references][]": ["${gcp_zone_1}","${gcp_zone_2}","${gcp_zone_3}"],
    "network_collection[networks_attributes][1][guid]": "1",
    "network_collection[networks_attributes][1][name]": "ert",
    "network_collection[networks_attributes][1][service_network]": "0",
    "network_collection[networks_attributes][1][subnets][0][iaas_identifier]": "${gcp_resource_prefix}-virt-net/${gcp_resource_prefix}-subnet-ert-${gcp_region}/${gcp_region}",
    "network_collection[networks_attributes][1][subnets][0][cidr]": "192.168.16.0/22",
    "network_collection[networks_attributes][1][subnets][0][reserved_ip_ranges]": "192.168.16.1-192.168.16.9",
    "network_collection[networks_attributes][1][subnets][0][dns]": "192.168.16.1,8.8.8.8",
    "network_collection[networks_attributes][1][subnets][0][gateway]": "192.168.16.1",
    "network_collection[networks_attributes][1][subnets][0][availability_zone_references][]": ["${gcp_zone_1}","${gcp_zone_2}","${gcp_zone_3}"],
    "network_collection[networks_attributes][2][guid]": "2",
    "network_collection[networks_attributes][2][name]": "services-1",
    "network_collection[networks_attributes][2][service_network]": "1",
    "network_collection[networks_attributes][2][subnets][0][iaas_identifier]": "${gcp_resource_prefix}-virt-net/${gcp_resource_prefix}-subnet-services-1-${gcp_region}/${gcp_region}",
    "network_collection[networks_attributes][2][subnets][0][cidr]": "192.168.20.0/22",
    "network_collection[networks_attributes][2][subnets][0][reserved_ip_ranges]": "192.168.20.1-192.168.20.9",
    "network_collection[networks_attributes][2][subnets][0][dns]": "192.168.20.1,8.8.8.8",
    "network_collection[networks_attributes][2][subnets][0][gateway]": "192.168.20.1",
    "network_collection[networks_attributes][2][subnets][0][availability_zone_references][]": ["${gcp_zone_1}","${gcp_zone_2}","${gcp_zone_3}"],
    "pipeline_extension": "fn_form_gen_networks"
  },
  "az_and_network_assignment": {
    "bosh_product[singleton_availability_zone_reference]": "${gcp_zone_1}",
    "bosh_product[network_reference]": "infrastructure",
    "pipeline_extension": "fn_form_gen_az_and_network_assignment"
  },
  "resources":{
    "product_resources_form[director][disk_type_id]": "",
    "product_resources_form[director][vm_type_id]": "",
    "product_resources_form[director][elb_names]": "",
    "product_resources_form[director][internet_connected]": "0",
    "product_resources_form[compilation][disk_type_id]": "",
    "product_resources_form[compilation][vm_type_id]": "",
    "product_resources_form[compilation][elb_names]": "",
    "product_resources_form[compilation][internet_connected]": "0"
  }
}]
EOF

iaas_configuration_json=$(echo "{
  \"iaas_configuration[project]\": \"${gcp_proj_id}\",
  \"iaas_configuration[default_deployment_tag]\": \"${gcp_resource_prefix}\",
  \"access_type\": \"keys\",
  \"iaas_configuration[auth_json]\":
    $(echo ${gcp_svc_acct_key})
}")

json_file_path="."
opsman_host="opsman.${pcf_ert_domain}"

# -
source pcf-pipelines/tasks/install-pcf-gcp/functions/misc.sh
# opsman_host
source pcf-pipelines/tasks/install-pcf-gcp/functions/config-director-json-fn-opsman-curl.sh
# json_file_path
source pcf-pipelines/tasks/install-pcf-gcp/functions/config-director-json-fn-opsman-auth.sh
# json_file_path
source pcf-pipelines/tasks/install-pcf-gcp/functions/config-director-json-fn-opsman-json-to-post-data.sh
# opsman_host, pcf_opsman_admin_passwd
source pcf-pipelines/tasks/install-pcf-gcp/functions/config-director-json-fn-opsman-extensions.sh
# -
source pcf-pipelines/tasks/install-pcf-gcp/functions/config-director-json-fn-opsman-config-director.sh

fn_config_director
