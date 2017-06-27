#!/bin/bash
set -e

root=$PWD

export GOOGLE_CREDENTIALS=${GCP_SERVICE_ACCOUNT_KEY}
export GOOGLE_PROJECT=${GCP_PROJECT_ID}
export GOOGLE_REGION=${GCP_REGION}

source "${root}/pcf-pipelines/functions/check_opsman_available.sh"

opsman_available=$(check_opsman_available $OPSMAN_URI)
if [[ $opsman_available == "available" ]]; then
  om-linux \
    --target https://$OPSMAN_URI \
    --skip-ssl-validation \
    --username $OPSMAN_USERNAME \
    --password $OPSMAN_PASSWORD \
    delete-installation
fi

echo "Deleting provisioned infrastructure..."
terraform destroy -force \
  -state $root/terraform-state/*.tfstate \
  -var "gcp_proj_id=dontcare" \
  -var "gcp_region=dontcare" \
  -var "gcp_zone_1=dontcare" \
  -var "gcp_zone_2=dontcare" \
  -var "gcp_zone_3=dontcare" \
  -var "prefix=dontcare" \
  -var "pcf_opsman_image_name=dontcare" \
  -var "pcf_ert_domain=dontcare" \
  -var "pcf_ert_ssl_cert=dontcare" \
  -var "pcf_ert_ssl_key=dontcare" \
  -var "ert_sql_instance_name=dontcare" \
  -var "opsman_allow_cidr=dontcare" \
  -var "db_app_usage_service_username=dontcare" \
  -var "db_app_usage_service_password=dontcare" \
  -var "db_autoscale_username=dontcare" \
  -var "db_autoscale_password=dontcare" \
  -var "db_diego_username=dontcare" \
  -var "db_diego_password=dontcare" \
  -var "db_notifications_username=dontcare" \
  -var "db_notifications_password=dontcare" \
  -var "db_routing_username=dontcare" \
  -var "db_routing_password=dontcare" \
  -var "db_uaa_username=dontcare" \
  -var "db_uaa_password=dontcare" \
  -var "db_ccdb_username=dontcare" \
  -var "db_ccdb_password=dontcare" \
  -var "db_accountdb_username=dontcare" \
  -var "db_accountdb_password=dontcare" \
  -var "db_networkpolicyserverdb_username=dontcare" \
  -var "db_networkpolicyserverdb_password=dontcare" \
  -var "db_nfsvolumedb_username=dontcare" \
  -var "db_nfsvolumedb_password=dontcare" \
  -var "db_locket_username=dontcare" \
  -var "db_locket_password=dontcare" \
  -var "db_silk_username=dontcare" \
  -var "db_silk_password=dontcare" \
  -state-out $root/wipe-output/terraform.tfstate \
  pcf-pipelines/install-pcf/gcp/terraform
