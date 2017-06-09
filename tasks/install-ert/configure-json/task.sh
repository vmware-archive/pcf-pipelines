#!/bin/bash

set -e

json_file_path="pcf-pipelines/tasks/install-ert/json_templates/${pcf_iaas}/${terraform_template}"
json_file_template="${json_file_path}/ert-template.json"

if [ ! -f "$json_file_template" ]; then
  echo "Error: can't find file=[${json_file_template}]"
  exit 1
fi

json_file="json_file/ert.json"

cp ${json_file_template} ${json_file}

if [[ ${pcf_ert_ssl_cert} == "generate" ]]; then
  echo "=============================================================================================="
  echo "Generating Self Signed Certs for sys.${pcf_ert_domain} & cfapps.${pcf_ert_domain} ..."
  echo "=============================================================================================="
  pcf-pipelines/tasks/scripts/gen_ssl_certs.sh "sys.${pcf_ert_domain}" "cfapps.${pcf_ert_domain}"
  export pcf_ert_ssl_cert=$(cat sys.${pcf_ert_domain}.crt)
  export pcf_ert_ssl_key=$(cat sys.${pcf_ert_domain}.key)
fi

system_domain=sys.${pcf_ert_domain}
ops_mgr_host="https://opsman.$pcf_ert_domain"
domains=$(cat <<-EOF
  {"domains": ["*.${system_domain}", "*.login.${system_domain}", "*.uaa.${system_domain}"] }
EOF
)
saml_cert_response=`om-linux -t $ops_mgr_host -u $pcf_opsman_admin -p $pcf_opsman_admin_passwd -k curl -p "/api/v0/certificates/generate" -x POST -d "$domains"`
saml_cert_pem=$(echo $saml_cert_response | jq --raw-output '.certificate')
saml_key_pem=$(echo $saml_cert_response | jq --raw-output '.key')

sed -i \
  -e "s/{{pcf_az_1}}/${pcf_az_1}/g" \
  -e "s/{{pcf_az_2}}/${pcf_az_2}/g" \
  -e "s/{{pcf_az_3}}/${pcf_az_3}/g" \
  -e "s/{{pcf_ert_domain}}/${pcf_ert_domain}/g" \
  -e "s/{{terraform_prefix}}/${terraform_prefix}/g" \
  -e "s/{{mysql_monitor_recipient_email}}/${mysql_monitor_recipient_email}/g" \
  ${json_file}

if [[ ${MYSQL_BACKUPS} == "scp" ]]; then
  cat > mysql_filter <<-'EOF'
    .properties.properties.".properties.mysql_backups" = {"value": $mysql_backups} |
    .properties.properties.".properties.mysql_backups.scp.server" = {"value": $mysql_backups_scp_server} |
    .properties.properties.".properties.mysql_backups.scp.port" = {"value": $mysql_backups_scp_port} |
    .properties.properties.".properties.mysql_backups.scp.user" = {"value": $mysql_backups_scp_user} |
    .properties.properties.".properties.mysql_backups.scp.key" = {"value": $mysql_backups_scp_key} |
    .properties.properties.".properties.mysql_backups.scp.destination" = {"value": $mysql_backups_scp_destination} |
    .properties.properties.".properties.mysql_backups.scp.cron_schedule" = {"value": $mysql_backups_scp_cron_schedule}
EOF

  jq \
    --arg mysql_backups "$MYSQL_BACKUPS" \
    --arg mysql_backups_scp_server "$MYSQL_BACKUPS_SCP_SERVER" \
    --arg mysql_backups_scp_port "$MYSQL_BACKUPS_SCP_PORT" \
    --arg mysql_backups_scp_user "$MYSQL_BACKUPS_SCP_USER" \
    --arg mysql_backups_scp_key "$MYSQL_BACKUPS_SCP_KEY" \
    --arg mysql_backups_scp_destination "$MYSQL_BACKUPS_SCP_DESTINATION" \
    --arg mysql_backups_scp_cron_schedule "$MYSQL_BACKUPS_SCP_CRON_SCHEDULE" \
    --from-file mysql_filter \
    $json_file > config.json
  mv config.json $json_file
fi

if [[ ${MYSQL_BACKUPS} == "s3" ]]; then
  echo "adding s3 mysql backup properties"
  cat > mysql_filter <<-'EOF'
    .properties.properties.".properties.mysql_backups" = {"value": $mysql_backups} |
    .properties.properties.".properties.mysql_backups.s3.endpoint_url" = {"value": $mysql_backups_s3_endpoint_url} |
    .properties.properties.".properties.mysql_backups.s3.bucket_name" = {"value": $mysql_backups_s3_bucket_name} |
    .properties.properties.".properties.mysql_backups.s3.bucket_path" = {"value": $mysql_backups_s3_bucket_path} |
    .properties.properties.".properties.mysql_backups.s3.access_key_id" = {"value": $mysql_backups_s3_access_key_id} |
    .properties.properties.".properties.mysql_backups.s3.secret_access_key" = {"value": { "secret": $mysql_backups_s3_secret_access_key}} |
    .properties.properties.".properties.mysql_backups.s3.cron_schedule" = {"value": $mysql_backups_s3_cron_schedule}
EOF

  jq \
    --arg mysql_backups "$MYSQL_BACKUPS" \
    --arg mysql_backups_s3_endpoint_url "$MYSQL_BACKUPS_S3_ENDPOINT_URL" \
    --arg mysql_backups_s3_bucket_name "$MYSQL_BACKUPS_S3_BUCKET_NAME" \
    --arg mysql_backups_s3_bucket_path "$MYSQL_BACKUPS_S3_BUCKET_PATH" \
    --arg mysql_backups_s3_access_key_id "$MYSQL_BACKUPS_S3_ACCESS_KEY_ID" \
    --arg mysql_backups_s3_secret_access_key "$MYSQL_BACKUPS_S3_SECRET_ACCESS_KEY" \
    --arg mysql_backups_s3_cron_schedule "$MYSQL_BACKUPS_S3_CRON_SCHEDULE" \
    --from-file mysql_filter \
    $json_file > config.json
  mv config.json $json_file
fi

cat > cert_filter <<-'EOF'
  .properties.properties.".properties.networking_point_of_entry.external_ssl.ssl_rsa_certificate".value = {
    "cert_pem": $cert_pem,
    "private_key_pem": $private_key_pem
  } |
  .properties.properties.".uaa.service_provider_key_credentials".value = {
    "cert_pem": $saml_cert_pem,
    "private_key_pem": $saml_key_pem
  }
EOF

jq \
  --arg cert_pem "$pcf_ert_ssl_cert" \
  --arg private_key_pem "$pcf_ert_ssl_key" \
  --arg saml_cert_pem "$saml_cert_pem" \
  --arg saml_key_pem "$saml_key_pem" \
  --from-file cert_filter \
  $json_file > config.json
mv config.json $json_file

db_creds=(
  db_app_usage_service_username
  db_app_usage_service_password
  db_autoscale_username
  db_autoscale_password
  db_diego_username
  db_diego_password
  db_notifications_username
  db_notifications_password
  db_routing_username
  db_routing_password
  db_uaa_username
  db_uaa_password
  db_ccdb_username
  db_ccdb_password
  db_accountdb_username
  db_accountdb_password
  db_networkpolicyserverdb_username
  db_networkpolicyserverdb_password
  db_nfsvolumedb_username
  db_nfsvolumedb_password  
)

for i in "${db_creds[@]}"
do
   eval "templateplaceholder={{${i}}}"
   eval "varname=\${$i}"
   eval "varvalue=$varname"
   echo "replacing value for ${templateplaceholder} in ${json_file} with the value of env var:${varname} "
   sed -i -e "s/$templateplaceholder/${varvalue}/g" ${json_file}
done

if [[ -e pcf-pipelines/tasks/install-ert/scripts/iaas-specific-config/${pcf_iaas}/run.sh ]]; then
  echo "Executing ${pcf_iaas} IaaS specific config ..."
  ./pcf-pipelines/tasks/install-ert/scripts/iaas-specific-config/${pcf_iaas}/run.sh
fi
