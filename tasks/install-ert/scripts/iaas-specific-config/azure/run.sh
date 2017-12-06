#!/bin/bash
set -e

json_file="json_file/ert.json"

cat > networking_poe_cert_filter <<-'EOF'
  .properties.properties.".properties.networking_point_of_entry.{{pcf_ert_networking_pointofentry}}.ssl_rsa_certificate".value = {
    "cert_pem": $cert_pem,
    "private_key_pem": $private_key_pem
  }
EOF

jq \
  --arg cert_pem "$pcf_ert_ssl_cert" \
  --arg private_key_pem "$pcf_ert_ssl_key" \
  --from-file networking_poe_cert_filter \
  $json_file > config.json
mv config.json $json_file

# Remove .properties.networking_point_of_entry.external_ssl.ssl_rsa_certificate
# added by generic configure-json script
jq \
  'del(.properties.properties.".properties.networking_point_of_entry.external_ssl.ssl_rsa_certificate")' \
  $json_file > config.json
mv config.json $json_file

cat > elb_filter <<-'EOF'
  .jobs.ha_proxy = {
    "instance_type": {
      "id": "automatic"
    },
    "instances": $haproxy_instance_count | tonumber,
    "elb_names": [
      $haproxy_elb_name
    ]
  } |
  .jobs.router = {
    "instance_type": {
      "id": "automatic"
    },
    "instances": $router_instance_count | tonumber,
    "elb_names": [
      $router_elb_name
    ]
  }
EOF

router_instance_count="$(jq '.jobs.router.instances' $json_file)"

if [[ "${pcf_ert_networking_pointofentry}" == "haproxy" ]]; then
  jq \
    --arg haproxy_instance_count 1 \
    --arg haproxy_elb_name "${terraform_prefix}-web-lb" \
    --arg router_instance_count ${router_instance_count} \
    --arg router_elb_name "" \
    --from-file elb_filter \
    $json_file > config.json
  mv config.json $json_file
  jq \
    'del(.jobs.router.elb_names)' \
    $json_file > config.json
  mv config.json $json_file
else
  jq \
    --arg haproxy_instance_count 0 \
    --arg haproxy_elb_name "" \
    --arg router_instance_count ${router_instance_count} \
    --arg router_elb_name "${terraform_prefix}-web-lb" \
    --from-file elb_filter \
    $json_file > config.json
  mv config.json $json_file
  jq \
    'del(.jobs.ha_proxy.elb_names)' \
    $json_file > config.json
  mv config.json $json_file
fi

sed -i \
  -e "s%{{pcf_ert_networking_pointofentry}}%${pcf_ert_networking_pointofentry}%g" \
  $json_file

if [[ "${azure_access_key}" != "" ]]; then
  # Use prefix to strip down a Storage Account Prefix String
  env_short_name=$(echo ${terraform_prefix} | tr -d "-" | tr -d "_" | tr -d "[0-9]")
  env_short_name=$(echo ${env_short_name:0:10})

  cat ${json_file} | jq \
    --arg azure_access_key "${azure_access_key}" \
    --arg azure_account_name "${env_short_name}${azure_account_name}" \
    --arg azure_buildpacks_container "${azure_buildpacks_container}" \
    --arg azure_droplets_container "${azure_droplets_container}" \
    --arg azure_packages_container "${azure_packages_container}" \
    --arg azure_resources_container "${azure_resources_container}" \
    '
    .properties.properties |= .+ {
      ".properties.system_blobstore.external_azure.access_key": {
        "value": {
          "secret": $azure_access_key
        }
      },
      ".properties.system_blobstore": {
        "value": "external_azure"
      },
      ".properties.system_blobstore.external_azure.account_name": {
        "value": $azure_account_name
      },
      ".properties.system_blobstore.external_azure.buildpacks_container": {
        "value": $azure_buildpacks_container
      },
      ".properties.system_blobstore.external_azure.droplets_container": {
        "value": $azure_droplets_container
      },
      ".properties.system_blobstore.external_azure.packages_container": {
        "value": $azure_packages_container
      },
      ".properties.system_blobstore.external_azure.resources_container": {
        "value": $azure_resources_container
      }
    }
    ' > /tmp/ert.json
  mv /tmp/ert.json ${json_file}
fi

