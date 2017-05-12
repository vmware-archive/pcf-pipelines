#!/bin/bash
set -e

#Make om-linux executable

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

cp /opt/terraform/terraform /usr/local/bin
CWD=$(pwd)


# Using aws admin account to copy the terraform template here
export AWS_ACCESS_KEY_ID=${TF_VAR_aws_access_key}
export AWS_SECRET_ACCESS_KEY=${TF_VAR_aws_secret_key}
export AWS_DEFAULT_REGION=${TF_VAR_aws_region}

#Clean AWS instances
pip install awscli
aws s3 cp s3://${bucket}/terraform.tfstate .
while read -r line
do
  `echo "$line" | awk '{print "export "$1"="$3}'`
done < <(terraform output)

export AWS_ACCESS_KEY_ID=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^secret | awk '{print $3}'`

json_file="json_file/ert.json"

export S3_ESCAPED=${S3_ENDPOINT//\//\\/}

cd $CWD

# Set JSON Config Template and inster Concourse Parameter Values
output_file_path="json_file/"

perl -pi -e "s/{{db_host}}/${db_host}/g" ${json_file}

perl -pi -e "s/{{aws_access_key}}/${AWS_ACCESS_KEY_ID}/g" ${json_file}
perl -pi -e "s%{{aws_secret_key}}%${AWS_SECRET_ACCESS_KEY}%g" ${json_file}
perl -pi -e "s/{{aws_region}}/${region}/g" ${json_file}
perl -pi -e "s/{{s3_endpoint}}/${S3_ESCAPED}/g" ${json_file}
perl -pi -e "s/{{syslog_host}}/${SYSLOG_HOST}/g" ${json_file}

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
)

for i in "${db_creds[@]}"
do
   eval "templateplaceholder={{${i}}}"
   eval "varname=\${$i}"
   eval "varvalue=$varname"
   echo "replacing value for ${templateplaceholder} in ${json_file} with the value of env var:${varname} "
   sed -i -e "s/$templateplaceholder/${varvalue}/g" ${json_file}
done
