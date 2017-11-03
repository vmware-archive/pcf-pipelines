#!/bin/bash

set -eu

function auth() {
  local project_id=$(echo "$GCP_SERVICE_ACCOUNT_KEY"| jq -r .project_id)
  gcloud config set project ${project_id}
  gcloud auth activate-service-account --key-file <(echo "$GCP_SERVICE_ACCOUNT_KEY")
}

function main() {

  auth

  local parent_dns_zone_name="$(get_dns_zone_name_by_domain ${PARENT_DNS_ZONE})"
  local child_dns_zone_name="$(get_dns_zone_name_by_domain ${CHILD_DNS_ZONE})"

  if [[ -z "${parent_dns_zone_name}" ]]; then
    echo "DNS Zone for ${parent_dns_zone_name} does not exist."
    exit 1
  fi

  if [[ -z "${child_dns_zone_name}" ]]; then
    echo "DNS Zone for ${child_dns_zone_name} does not exist."
    exit 1
  fi

  echo "Starting dns record set transaction..."
  gcloud dns record-sets transaction start --zone ${parent_dns_zone_name}

  echo "Removing old child dns NS record set..."
  remove_old_child_ns_record_set ${parent_dns_zone_name}

  echo "Adding new child dns NS record set..."
  add_child_ns_record_set ${parent_dns_zone_name} ${child_dns_zone_name}

  gcloud dns record-sets transaction execute --zone ${parent_dns_zone_name}
}

function get_dns_zone_name_by_domain() {
  local domain_name="${1}"
  local dns_zone_name="$(gcloud dns managed-zones list \
    --filter "DNS_NAME~^${domain_name}.$" \
    --format json | jq -r ".[0].name")"

  echo "${dns_zone_name}"
}

function remove_old_child_ns_record_set() {
  local parent_dns_zone_name="${1}"
  local child_record_json="$(gcloud dns record-sets list \
    --zone ${parent_dns_zone_name} \
    --format json \
    --filter NAME~^${CHILD_DNS_ZONE}.$)"

  if [[ "[]" != "${child_record_json}" ]]; then
    local ttl="$(echo ${child_record_json} | jq -r '.[0].ttl')"
    local rrdata="$(echo ${child_record_json} | jq -r '.[0].rrdatas[]')"
    gcloud dns record-sets transaction remove --zone "${parent_dns_zone_name}" \
      --name "${CHILD_DNS_ZONE}." \
      --ttl "${ttl}" \
      --type "NS" \
      ${rrdata}
  fi
}

function add_child_ns_record_set() {
  local parent_dns_zone_name="${1}"
  local child_dns_zone_name="${2}"
  local rrdata="$(gcloud dns managed-zones describe \
    --format=json \
    ${child_dns_zone_name} | jq -r .nameServers[])"

  gcloud dns record-sets transaction add --zone "${parent_dns_zone_name}" \
    --name "${CHILD_DNS_ZONE}." \
    --ttl "60" \
    --type "NS" \
    ${rrdata}
}

main
