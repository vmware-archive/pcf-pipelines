#!/bin/bash
set -e

echo "$PEM" > pcf.pem
chmod 0600 pcf.pem

CWD=$(pwd)
pushd $CWD
  cd pcf-pipelines/tasks/install-pcf-aws/terraform/
  cp $CWD/terraform-state/terraform.tfstate .

  while read -r line
  do
    `echo "$line" | awk '{print "export "$1"="$3}'`
  done < <(terraform output -state *.tfstate)

  export RDS_PASSWORD=`terraform state show aws_db_instance.pcf_rds | grep ^password | awk '{print $3}'`
popd

scp -i pcf.pem -o StrictHostKeyChecking=no pcf-pipelines/tasks/install-pcf-aws/databases.sql ubuntu@opsman.${ERT_DOMAIN}:/tmp/.
ssh -i pcf.pem -o StrictHostKeyChecking=no ubuntu@opsman.${ERT_DOMAIN} "mysql -h $db_host -u $db_username -p$RDS_PASSWORD < /tmp/databases.sql"
