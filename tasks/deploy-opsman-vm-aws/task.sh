#!/bin/bash -u

function main() {

local cwd
cwd="${1}"

gem install terraforming --no-ri --no-rdoc
chmod +x terraform/terraform
CMD_PATH="terraform/terraform"

IAAS_CONFIGURATION=$(cat <<-EOF
provider "aws" {
  region = "${AWS_REGION}"
  access_key = "${AWS_ACCESS_KEY_ID}"
  secret_key = "${AWS_SECRET_ACCESS_KEY}"
}

resource "aws_instance" "${AWS_INSTANCE}" {
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

resource "aws_route53_record" "${ROUTE53}" {
  zone_id = "${ROUTE53_ZONE_ID}"
  name = "${OPSMAN_SUBDOMAIN}"
  type = "CNAME"
  ttl = "300"
  records = ["\${aws_instance.${AWS_INSTANCE}.public_dns}"]
}
EOF
)
  echo $IAAS_CONFIGURATION > ./opsman_settings.tf

  cat ./opsman_settings.tf

  echo "Destroying current Ops Manager..."
  terraforming ec2 --tfstate > ./terraform.tfstate
  terraforming r53r --tfstate --merge ./terraform.tfstate --overwrite
  RESOURCE_TO_DESTROY="aws_instance.${AWS_INSTANCE}"
  ./${CMD_PATH} destroy -target=$RESOURCE_TO_DESTROY -force

  rm ./terraform.tfstate

  echo "Creating Ops Manager instance in AWS..."
  ./${CMD_PATH} apply

# verify that ops manager started
  started=false
  timeout=$((SECONDS+${OPSMAN_TIMEOUT}))
  export URL="https://${OPSMAN_SUBDOMAIN}.${OPSMAN_DOMAIN}"

  echo "Starting Ops manager on ${URL}"

  timeout=$((SECONDS+${OPSMAN_TIMEOUT}))
  while [[ $started ]]; do
    HTTP_OUTPUT=$(curl --write-out %{http_code} --silent -k --output /dev/null ${URL})
    if [[ $HTTP_OUTPUT == *"302"* || $HTTP_OUTPUT == *"301"* ]]; then
      echo "Site is started! $HTTP_OUTPUT"
      break
    else
      echo "Ops manager is not running on ${URL}..."
      if [[ $SECONDS -gt $timeout ]]; then
        echo "Timed out waiting for ops manager site to start."
        exit 1
      fi
    fi
  done

}
main "${PWD}"
