#!/bin/bash -eu

function main() {

local cwd
cwd="${1}"

CMD_PATH="terraform/bin/terraform"

chmod +x iaas-util/cliaas-linux
AWS_UTIL_PATH="iaas-util/cliaas-linux"

AMI=$(grep ${AWS_REGION} pivnet-opsmgr/*AWS.yml | awk '{split($0, a); print a[2]}')
echo "deploying ami: ${AMI} into region ${AWS_REGION}"

IAAS_CONFIGURATION=$(cat <<-EOF
provider "aws" {
  region = "${AWS_REGION}"
  access_key = "${AWS_ACCESS_KEY_ID}"
  secret_key = "${AWS_SECRET_ACCESS_KEY}"
}

resource "aws_instance" "ops-manager-to-provision" {
  ami = "${AMI}"
  instance_type = "${INSTANCE_TYPE}"
  key_name = "${KEY_NAME}"
  subnet_id = "${SUBNET_ID}"
  associate_public_ip_address = "true"
  instance_initiated_shutdown_behavior = "stop"
  vpc_security_group_ids = ["${SECURITY_GROUP}"]
  tags {
       Name = "${AWS_INSTANCE_NAME}"
   }
}

resource "aws_route53_record" "dns-record-to-provision" {
  zone_id = "${ROUTE53_ZONE_ID}"
  name = "${OPSMAN_SUBDOMAIN}"
  type = "CNAME"
  ttl = "300"
  records = ["\${aws_instance.ops-manager-to-provision.public_dns}"]
}
EOF
)
  echo $IAAS_CONFIGURATION > ./opsman_settings.tf

  read OLD_OPSMAN_INSTANCE ERR < <(./${AWS_UTIL_PATH} "${AWS_INSTANCE_NAME}")

  if [ -n "$OLD_OPSMAN_INSTANCE" ]
  then
    echo "Destroying old Ops Manager instance. ${OLD_OPSMAN_INSTANCE}"
    ./${CMD_PATH} import aws_instance.ops-manager-to-purge ${OLD_OPSMAN_INSTANCE}
    ./${CMD_PATH} destroy -state=./terraform.tfstate -target=aws_instance.ops-manager-to-purge -force
    rm ./terraform.tfstate
  fi

  echo "Provisioning Ops Manager"
  cat ./opsman_settings.tf
  ./${CMD_PATH} apply

# verify that ops manager started
  started=false
  timeout=$((SECONDS+${OPSMAN_TIMEOUT}))

  echo "Starting Ops manager on ${OPSMAN_URI}"

  timeout=$((SECONDS+${OPSMAN_TIMEOUT}))
  set +e
  while [[ $started ]]; do
    HTTP_OUTPUT=$(curl --write-out %{http_code} --silent -k --output /dev/null ${OPSMAN_URI})
    if [[ $HTTP_OUTPUT == *"302"* || $HTTP_OUTPUT == *"301"* ]]; then
      echo "Site is started! $HTTP_OUTPUT"
      exit 0
    else
      if [[ $SECONDS -gt $timeout ]]; then
        echo "Timed out waiting for ops manager site to start."
        exit 1
      fi
    fi
  done
  set -e
}
main "${PWD}"
