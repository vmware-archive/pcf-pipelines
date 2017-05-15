#!/bin/bash
set -e

json_file="json_file/ert.json"

echo $gcp_svc_acct_key > /tmp/blah
gcloud auth activate-service-account --key-file /tmp/blah
rm -rf /tmp/blah

gcloud config set project $gcp_proj_id
gcloud config set compute/region $gcp_region

gcloud_sql_instance_ip=$(
  gcloud sql instances list --format json |
  jq --raw-output --arg prefix $terraform_prefix '.[] | select(.instance | startswith($prefix)) | .ipAddresses[0].ipAddress'
)

sed -i \
  -e "s/{{db_host}}/${gcloud_sql_instance_ip}/g" \
  -e "s/{{gcloud_sql_instance_username}}/${pcf_opsman_admin}/g" \
  -e "s/{{gcloud_sql_instance_password}}/${pcf_opsman_passwd}/g" \
  -e "s/{{gcp_storage_access_key}}/${gcp_storage_access_key}/g" \
  -e "s/{{gcp_storage_secret_key}}/${gcp_storage_secret_key}/g" \
  $json_file
