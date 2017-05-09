#!/bin/bash
set -e

json_file="json_file/ert.json"

#############################################################
#################### GCP Auth  & functions ##################
#############################################################
echo $gcp_svc_acct_key > /tmp/blah
gcloud auth activate-service-account --key-file /tmp/blah
rm -rf /tmp/blah

gcloud config set project $gcp_proj_id
gcloud config set compute/region $gcp_region


#############################################################
# get GCP unique SQL instance ID & set params in JSON       #
#############################################################
gcloud_sql_instance_cmd="gcloud sql instances list --format json | jq '.[] | select(.instance | startswith(\"${terraform_prefix}\")) | .instance' | tr -d '\"'"
gcloud_sql_instance=$(eval ${gcloud_sql_instance_cmd})
gcloud_sql_instance_ip=$(gcloud sql instances list | grep ${gcloud_sql_instance} | awk '{print$4}')

declare -a arr=(
"db_app_usage_service_username"
"db_app_usage_service_password"
"db_autoscale_username"
"db_autoscale_password"
"db_diego_username"
"db_diego_password"
"db_notifications_username"
"db_notifications_password"
"db_routing_username"
"db_routing_password"
"db_uaa_username"
"db_uaa_password"
"db_ccdb_username"
"db_ccdb_password"
)

echo "finding variables to replace in your json config file using the value from the env variable of the same name"
for i in "${arr[@]}"
do
   eval "templateplaceholder={{${i}}}"
   eval "varname=\${$i}"
   eval "varvalue=$varname"
   echo "replacing value for ${templateplaceholder} in ${json_file} with the value of env var:${varname} "
   sed -i -e "s/$templateplaceholder/${varvalue}/g" ${json_file}
done

#############################################################
# Set GCP Storage Setup for GCP Buckets                     #
#############################################################

perl -pi -e "s|{{gcp_storage_access_key}}|${gcp_storage_access_key}|g" ${json_file}
perl -pi -e "s|{{gcp_storage_secret_key}}|${gcp_storage_secret_key}|g" ${json_file}
