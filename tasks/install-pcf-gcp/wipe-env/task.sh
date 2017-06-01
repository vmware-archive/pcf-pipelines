#!/bin/bash
set -e

root=$PWD

export GOOGLE_CREDENTIALS=${GCP_SERVICE_ACCOUNT_KEY}
export GOOGLE_PROJECT=${GCP_PROJECT_ID}
export GOOGLE_REGION=${GCP_REGION}

echo "Checking for existence of ops manager..."
if [[ $(dig +nocmd ${OPSMAN_URI} +noall +answer | wc -l) -ne 0 ]]; then 
  echo "Deleting PCF installation..."
  om-linux \
    --target https://$OPSMAN_URI \
    --skip-ssl-validation \
    --username $OPSMAN_USERNAME \
    --password $OPSMAN_PASSWORD \
    delete-installation
else
  echo "No ops manager could be found."
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
  -var "db_app_usage_service_username=${DB_APP_USAGE_SERVICE_USERNAME}" \
  -var "db_app_usage_service_password=${DB_APP_USAGE_SERVICE_PASSWORD}" \
  -var "db_autoscale_username=${DB_AUTOSCALE_USERNAME}" \
  -var "db_autoscale_password=${DB_AUTOSCALE_PASSWORD}" \
  -var "db_diego_username=${DB_DIEGO_USERNAME}" \
  -var "db_diego_password=${DB_DIEGO_PASSWORD}" \
  -var "db_notifications_username=${DB_NOTIFICATIONS_USERNAME}" \
  -var "db_notifications_password=${DB_NOTIFICATIONS_PASSWORD}" \
  -var "db_routing_username=${DB_ROUTING_USERNAME}" \
  -var "db_routing_password=${DB_ROUTING_PASSWORD}" \
  -var "db_uaa_username=${DB_UAA_USERNAME}" \
  -var "db_uaa_password=${DB_UAA_PASSWORD}" \
  -var "db_ccdb_username=${DB_CCDB_USERNAME}" \
  -var "db_ccdb_password=${DB_CCDB_PASSWORD}" \
  -var "db_accountdb_username=${DB_ACCOUNTDB_USERNAME}" \
  -var "db_accountdb_password=${DB_ACCOUNTDB_PASSWORD}" \
  -var "db_networkpolicyserverdb_username=${DB_NETWORKPOLICYSERVERDB_USERNAME}" \
  -var "db_networkpolicyserverdb_password=${DB_NETWORKPOLICYSERVERDB_PASSWORD}" \
  -var "db_nfsvolumedb_username=${DB_NFSVOLUMEDB_USERNAME}" \
  -var "db_nfsvolumedb_password=${DB_NFSVOLUMEDB_PASSWORD}" \
  -state-out $root/wipe-output/terraform.tfstate \
  pcf-pipelines/tasks/install-pcf-gcp/terraform
