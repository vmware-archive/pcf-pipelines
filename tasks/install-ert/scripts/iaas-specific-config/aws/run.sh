#!/bin/bash
set -e

#Make om-linux executable

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

cp /opt/terraform/terraform /usr/local/bin

cd pcfawsops-terraform-state-get
  while read -r line
  do
    `echo "$line" | awk '{print "export "$1"="$3}'`
  done < <(terraform output)

  export AWS_ACCESS_KEY_ID=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^id | awk '{print $3}'`
  export AWS_SECRET_ACCESS_KEY=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^secret | awk '{print $3}'`
cd -

json_file="json_file/ert.json"

# Set JSON Config Template and inster Concourse Parameter Values

perl -pi -e "s/{{db_host}}/${db_host}/g" ${json_file}

perl -pi -e "s/{{aws_access_key}}/${AWS_ACCESS_KEY_ID}/g" ${json_file}
perl -pi -e "s%{{aws_secret_key}}%${AWS_SECRET_ACCESS_KEY}%g" ${json_file}
perl -pi -e "s/{{aws_region}}/${region}/g" ${json_file}
perl -pi -e "s%{{s3_endpoint}}%${S3_ENDPOINT}%g" ${json_file}
perl -pi -e "s/{{syslog_host}}/${SYSLOG_HOST}/g" ${json_file}
