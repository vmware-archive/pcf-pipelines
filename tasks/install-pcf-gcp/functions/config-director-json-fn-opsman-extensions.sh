#!/bin/bash
set -e

function fn_form_gen_availability_zones {
  return_var=""
  local json=${@}

  for zone in $(echo ${json} | jq .availability_zones[]); do
    my_zone=$(echo ${zone} | tr -d '"' | tr -d '\n' | tr -d '\r')
    return_var="${return_var}&availability_zones[availability_zones][][guid]=&availability_zones[availability_zones][][iaas_identifier]=${my_zone}"
  done
  echo $return_var
}

# Only Coded to support single Subnet per Network ATM MG
function fn_form_gen_networks {
  return_var=""
  local json=${@}

  fn_metadata_cmd="echo \${json} | jq ."

  chk_auth=$(fn_opsman_auth)

  #for key in $(echo ${json} | jq 'keys' | jq .[] ); do #This one sorts Alpha, was replaced to sort raw
  for key in $(echo ${json} | jq -r 'to_entries[] | "\(.key)"' | sed 's/^/"/' | sed 's/$/"/' ); do
    fn_metadata_key_value=$(eval ${fn_metadata_cmd} | jq .${key} | tr -d '"')
    fn_metadata_key=$(echo $key | tr -d '"')

    if [[ ${fn_metadata_key} == "pipeline_extension" ]]; then
      echo ""
    elif [[ ${fn_metadata_key} == *"availability_zone_references"* ]]; then
      net_guid=$(echo ${fn_metadata_key} | awk -F "[" '{print$3}' | tr -d "]")
      for set_zone in $(eval ${fn_metadata_cmd} | jq .${key}[] | tr -d '"'); do
        set_zone_id=$(fn_opsman_curl "GET" "infrastructure/availability_zones/edit" 2>&1 | grep -B 2 -A 2 ${set_zone} | grep "value=" | awk '{print$4}' | awk -F "'" '{print$2}' | tr -d '\n' | tr -d '\r' | sed 's/text//' )
        return_var="${return_var}&network_collection[networks_attributes][${net_guid}][subnets][0][availability_zone_references][]=${set_zone_id}"
      done
      return_var="${return_var}&network_collection[networks_attributes][${net_guid}][subnets][0][availability_zone_references][]="
    else
      return_var="${return_var}&${fn_metadata_key}=${fn_metadata_key_value}"
    fi
  done
  echo ${return_var}
}

function fn_form_gen_az_and_network_assignment {
  return_var=""
  local json=${@}

  fn_metadata_cmd="echo \${json} | jq ."

  chk_auth=$(fn_opsman_auth)

  for key in $(echo ${json} | jq 'keys' | jq .[] ); do
    fn_metadata_key_value=$(eval ${fn_metadata_cmd} | jq .${key} | tr -d '"')
    fn_metadata_key=$(echo $key | tr -d '"')
    if [[ ${fn_metadata_key} == *"pipeline_extension"* ]]; then
      echo ""
    elif [[ ${fn_metadata_key} == *"singleton_availability_zone_reference"* ]]; then
      set_zone_id=$(fn_opsman_curl "GET" "infrastructure/availability_zones/edit" 2>&1 | grep -B 2 -A 2 ${fn_metadata_key_value} | grep "value=" | awk '{print$4}' | awk -F "'" '{print$2}' | tr -d '\n' | tr -d '\r' | sed 's/text//' )
      return_var="${return_var}&${fn_metadata_key}=${set_zone_id}"
    elif [[ ${fn_metadata_key} == *"network_reference"* ]]; then
      set_net_id=$(fn_opsman_curl "GET" "infrastructure/networks/edit" 2>&1 | grep -B 2 -A 2 ${fn_metadata_key_value} | grep "network_collection_networks_attributes" | head -n 1 | awk -F "value=" '{print$2}' | awk '{print$1}' | tr -d '"')
      return_var="${return_var}&${fn_metadata_key}=${set_net_id}"
    else
      echo ""
    fi
  done
  echo ${return_var}
}

function fn_form_gen_ert_az_and_network_assignments {
  return_var=""
  local json=${@}

  # Get ERT Product ID To set URL
  uaac target https://${opsman_host}/uaa --skip-ssl-validation > /dev/null 2>&1
  uaac token owner get opsman admin -s "" -p ${pcf_opsman_admin_passwd} > /dev/null 2>&1
  export opsman_bearer_token=$(uaac context | grep access_token | awk -F ":" '{print$2}' | tr -d ' ')

  ert_product_id=$(curl -s -k -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $opsman_bearer_token" \
    "https://${opsman_host}/api/v0/staged/products" | \
    jq '.[] | select(.type == "cf") | .guid'  | tr -d '"')

  # Auth to OpsMan
  ch_auth=$(fn_opsman_auth)

  # Wipe any previous HTML out
  if [[ -f /tmp/az_and_network_assignments-html.out ]]; then
    rm -rf /tmp/az_and_network_assignments-html.out
  fi
  # Get Possible field values & output to html response file
  chk_get_prods=$(fn_opsman_curl "GET" "products/${ert_product_id}/az_and_network_assignments/edit" "" "" "" "-o /tmp/az_and_network_assignments-html.out")

  # Check if we got a HTML response file
  if [[ ! -f /tmp/az_and_network_assignments-html.out ]]; then
    fn_err "fn_form_gen_ert_az_and_network_assignments: no output file from products/${ert_product_id}/az_and_network_assignments/edit"
  fi

  # Read JSON
  fn_metadata_cmd="echo \${json} | jq ."

  # Build POST Data
  for key in $(echo ${json} | jq -r 'to_entries[] | "\(.key)"' | sed 's/^/"/' | sed 's/$/"/' ); do
    fn_metadata_key_value=$(eval ${fn_metadata_cmd} | jq .${key} | tr -d '"')
    fn_metadata_key=$(echo $key | tr -d '"')
    if [[ ${fn_metadata_key} == *"pipeline_extension"* ]]; then
      echo ""
    elif [[ ${fn_metadata_key} == "product_singleton_availability_zone_reference" ]]; then
      set_singleton_zone_id=$(sed -n '/<!DOCTYPE html>/,$p' /tmp/az_and_network_assignments-html.out | grep "${fn_metadata_key}" | grep "${fn_metadata_key_value}" | awk -F "value=" '{print$2}' | awk -F '"' '{print$2}')
      return_var="${return_var}&product[singleton_availability_zone_reference]=${set_singleton_zone_id}"
    elif [[ ${fn_metadata_key} == "product_availability_zone_references" ]]; then
      for i in $(eval ${fn_metadata_cmd} | jq .product_availability_zone_references[] ); do
        get_zone_id=$(echo $i | tr -d '"')
        set_balance_zone_id=$(sed -n '/<!DOCTYPE html>/,$p' /tmp/az_and_network_assignments-html.out | grep "${fn_metadata_key}" | grep "${get_zone_id}" | awk -F "value=" '{print$2}' | awk -F '"' '{print$2}')
        return_var="${return_var}&product[availability_zone_references][]=${set_balance_zone_id}"
      done
      return_var="${return_var}&product[availability_zone_references][]="
    elif [[ ${fn_metadata_key} == "product[network_reference]" ]]; then
      set_net_id=$(sed -n '/<!DOCTYPE html>/,$p' /tmp/az_and_network_assignments-html.out | grep "${fn_metadata_key_value}" | awk -F "value=" '{print$2}' | awk -F '"' '{print$2}')
      return_var="${return_var}&product[network_reference]=${set_net_id}"
    fi
  done

  echo $return_var
}
