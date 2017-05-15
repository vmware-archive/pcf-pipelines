#!/bin/bash
set -e

export PATH=$PATH:/opt/terraform

cd pcfawsops-terraform-state-get
  while read -r line
  do
    `echo "$line" | awk '{print "export "$1"="$3}'`
  done < <(terraform output)

  export AWS_ACCESS_KEY_ID=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^id | awk '{print $3}'`
  export AWS_SECRET_ACCESS_KEY=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^secret | awk '{print $3}'`
cd -

sed -i \
  -e "s/{{db_host}}/${db_host}/g" \
  -e "s/{{aws_access_key}}/${AWS_ACCESS_KEY_ID}/g" \
  -e "s%{{aws_secret_key}}%${AWS_SECRET_ACCESS_KEY}%g" \
  -e "s/{{aws_region}}/${region}/g" \
  -e "s%{{s3_endpoint}}%${S3_ENDPOINT}%g" \
  -e "s/{{syslog_host}}/${SYSLOG_HOST}/g" \
  json_file/ert.json
