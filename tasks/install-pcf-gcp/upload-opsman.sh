#!/bin/bash
set -eu

export PATH=/opt/terraform:$PATH

export GOOGLE_CREDENTIALS=${GCP_SERVICE_ACCOUNT_KEY}
export GOOGLE_PROJECT=${GCP_PROJECT_ID}
export GOOGLE_REGION=${GCP_REGION}

# us: ops-manager-us/pcf-gcp-1.9.2.tar.gz -> ops-manager-us/pcf-gcp-1.9.2.tar.gz
pcf_opsman_bucket_path=$(grep -i 'us:.*.tar.gz' pivnet-opsmgr/*GCP.yml | cut -d' ' -f2)

# ops-manager-us/pcf-gcp-1.9.2.tar.gz -> opsman-pcf-gcp-1-9-2
pcf_opsman_image_name=$(echo $pcf_opsman_bucket_path | sed 's%.*/\(.*\).tar.gz%opsman-\1%' | sed 's/\./-/g')

mkdir terraform && cd terraform

cat > image.tf <<EOF
resource "google_compute_image" "ops-mgr" {
  name = "$pcf_opsman_image_name"
  project = "$GCP_PROJECT_ID"
  family = "pcf-opsman"
  description = "Pivotal Cloud Foundry Operations Manager"

  raw_disk {
    source = "gs://${pcf_opsman_bucket_path}"
  }
}
EOF

set +e
terraform apply
