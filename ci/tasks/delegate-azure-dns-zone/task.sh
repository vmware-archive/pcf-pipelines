#!/bin/bash

set -eu

function main() {
  az login \
    --service-principal \
    -u "${AZURE_SERVICE_PRINCIPAL_ID}" \
    -p "${AZURE_SERVICE_PRINCIPAL_PASSWORD}" \
    --tenant "${AZURE_TENANT_ID}"

  echo "Adding new child dns NS record set..."
  add_child_ns_record_set_to_parent \
    "${RESOURCE_GROUP}" \
    "${PARENT_DNS_ZONE}" \
    "${CHILD_DNS_ZONE_NAME}" \
}

function add_child_ns_record_set_to_parent() {
  local resource_group="${1}"
  local parent_dns_zone="${2}"
  local child_dns_zone_name="${3}"
  local nameservers=$(az network dns record-set list \
    --resource-group "${resource_group}" | \
    --zone-name "${child_dns_zone_name}.${parent_dns_zone}" \
    jq -r '.[] |
      select(.name == "@" and .type == "Microsoft.Network/dnszones/NS")
        .nsRecords[].nsdname')

  az network dns record-set ns create \
    --resource-group "${resource_group}" \
    --zone-name "${parent_dns_zone}" \
    --name "${child_dns_zone_name}" \
    --ttl "60"

  for nameserver in ${nameservers}; do
    az network dns record-set ns add-record \
      --resource-group "${resource_group}" \
      --zone-name "${parent_dns_zone}" \
      --record-set-name "${child_dns_zone_name}" \
      --nsdname "${nameserver}"
  done
}

main
