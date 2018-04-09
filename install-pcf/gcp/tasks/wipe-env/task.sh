#!/bin/bash
set -eu

root=$PWD

export GOOGLE_CREDENTIALS=${GCP_SERVICE_ACCOUNT_KEY}
export GOOGLE_PROJECT=${GCP_PROJECT_ID}
export GOOGLE_REGION=${GCP_REGION}

source "${root}/pcf-pipelines/functions/check_opsman_available.sh"

opsman_available=$(check_opsman_available $OPSMAN_DOMAIN_OR_IP_ADDRESS)
if [[ $opsman_available == "available" ]]; then
  om-linux \
    --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
    --skip-ssl-validation \
    --username "$OPSMAN_USERNAME" \
    --password "$OPSMAN_PASSWORD" \
    delete-installation
fi

# Create cliaas config

echo "$GCP_SERVICE_ACCOUNT_KEY" > gcpcreds.json
cat > cliaas_config.yml <<EOF
gcp:
  credfile: gcpcreds.json
  zone: ${OPSMAN_ZONE}
  project: ${GCP_PROJECT_ID}
  disk_image_url: dontmatter
EOF

# Get a list of opsman machines
gcloud auth activate-service-account --key-file gcpcreds.json
gcloud config set project $GCP_PROJECT_ID
OPSMAN_INSTANCES=$(gcloud compute instances list --filter "NAME ~ '$GCP_RESOURCE_PREFIX-ops-manager'" --format json | jq -r '.[].name')

for OPSMAN_INSTANCE in $OPSMAN_INSTANCES; do
  cliaas-linux -c cliaas_config.yml delete-vm -i "${OPSMAN_INSTANCE}"
done

# cliaas is asynch. Spin for a little bit before proceeding
for attempt in $(seq 60); do
  REMAINING=$(gcloud compute instances list --filter "NAME ~ '$GCP_RESOURCE_PREFIX-ops-manager'" --format json | jq '.|length')
  if [ "$REMAINING" -gt 0 ]; then
    echo "$REMAINING opsman machines remaining..."
    sleep 2
  else
    break
  fi
done

terraform init pcf-pipelines/install-pcf/gcp/terraform

echo "Deleting provisioned infrastructure..."
terraform destroy -force \
  -state $root/terraform-state/*.tfstate \
  -var "gcp_proj_id=dontcare" \
  -var "gcp_region=dontcare" \
  -var "gcp_zone_1=dontcare" \
  -var "gcp_zone_2=dontcare" \
  -var "gcp_zone_3=dontcare" \
  -var "gcp_storage_bucket_location=dontcare" \
  -var "prefix=dontcare" \
  -var "pcf_opsman_image_name=dontcare" \
  -var "pcf_ert_domain=dontcare" \
  -var "system_domain=dontcare" \
  -var "apps_domain=dontcare" \
  -var "pcf_ert_ssl_cert=dontcare" \
  -var "pcf_ert_ssl_key=dontcare" \
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
  -var "droplets_bucket=dontcare" \
  -var "http_lb_backend_name=dontcare" \
  -var "ops_manager_public_ip=dontcare" \
  -var "ert_cidr=dontcare" \
  -var "pub_ip_ssh_tcp_lb=dontcare" \
  -var "dynamic_svc_net_1_cidr=dontcare" \
  -var "packages_bucket=dontcare" \
  -var "ops_manager_cidr=dontcare" \
  -var "resources_bucket=dontcare" \
  -var "svc_net_1_subnet=dontcare" \
  -var "ops_manager_subnet=dontcare" \
  -var "svc_net_1_cidr=dontcare" \
  -var "pub_ip_global_pcf=dontcare" \
  -var "sql_instance_ip=dontcare" \
  -var "ops_manager_dns=dontcare" \
  -var "tcp_router_pool=dontcare" \
  -var "pub_ip_ssh_and_doppler=dontcare" \
  -var "dynamic_svc_net_1_gateway=dontcare" \
  -var "ert_gateway=dontcare" \
  -var "pub_ip_opsman=dontcare" \
  -var "network_name=dontcare" \
  -var "ops_manager_gateway=dontcare" \
  -var "svc_net_1_gateway=dontcare" \
  -var "dynamic_svc_net_1_subnet=dontcare" \
  -var "ert_certificate=dontcare" \
  -var "director_blobstore_bucket=dontcare" \
  -var "ert_certificate_key=dontcare" \
  -var "buildpacks_bucket=dontcare" \
  -var "env_dns_zone_name_servers=dontcare" \
  -var "ert_subnet=dontcare" \
  -state-out $root/wipe-output/terraform.tfstate \
  pcf-pipelines/install-pcf/gcp/terraform
