#!/bin/bash
set -e

cd terraform-state
  output_json=$(terraform output --json)
  db_host=$(echo $output_json | jq --raw-output '.db_host.value')
  aws_region=$(echo $output_json | jq --raw-output '.region.value')
  aws_access_key=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^id | awk '{print $3}'`
  aws_secret_key=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^secret | awk '{print $3}'`
cd -

sed -i \
  -e "s%{{db_host}}%${db_host}%g" \
  -e "s%{{aws_access_key}}%${aws_access_key}%g" \
  -e "s%{{aws_secret_key}}%${aws_secret_key}%g" \
  -e "s%{{aws_region}}%${aws_region}%g" \
  -e "s%{{s3_endpoint}}%${S3_ENDPOINT}%g" \
  -e "s%{{syslog_host}}%${SYSLOG_HOST}%g" \
  json_file/ert.json
