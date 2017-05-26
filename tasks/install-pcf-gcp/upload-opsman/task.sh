#!/bin/bash
set -eu

google_creds_json=$(mktemp)
echo $GCP_SERVICE_ACCOUNT_KEY > $google_creds_json
gcloud auth activate-service-account --key-file $google_creds_json
gcloud config set project $GCP_PROJECT_ID
gcloud config set compute/region $GCP_REGION

# us: ops-manager-us/pcf-gcp-1.9.2.tar.gz -> ops-manager-us/pcf-gcp-1.9.2.tar.gz
pcf_opsman_bucket_path=$(grep -i 'us:.*.tar.gz' pivnet-opsmgr/*GCP.yml | cut -d' ' -f2)

# ops-manager-us/pcf-gcp-1.9.2.tar.gz -> opsman-pcf-gcp-1-9-2
pcf_opsman_image_name=$(echo $pcf_opsman_bucket_path | sed 's%.*/\(.*\).tar.gz%opsman-\1%' | sed 's/\./-/g')

if [[ -z $(gcloud compute images list | grep $pcf_opsman_image_name) ]]; then
  echo "creating image ${pcf_opsman_image_name}"
  gcloud compute images create $pcf_opsman_image_name \
    --family pcf-opsman \
    --source-uri "gs://${pcf_opsman_bucket_path}"
else
  echo "image ${pcf_opsman_image_name} already exists"
fi
