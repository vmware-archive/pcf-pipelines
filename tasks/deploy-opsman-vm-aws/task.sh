#!/bin/bash -eu

function main() {

  # chmod +x terraform/terraform
  CMD_PATH="terraform/terraform"

  local cwd
  cwd="${1}"

IAAS_CONFIGURATION=$(cat <<-EOF
provider "aws" {
  region = "${REGION}"
  access_key = "${AWS_ACCESS_KEY_ID}"
  secret_key = "${AWS_SECRET_ACCESS_KEY}"
}

resource "aws_instance" "${AWS_INSTANCE}" {
  ami = "${AMI}"
  instance_type = "${INSTANCE_TYPE}"
  key_name = "${KEY_NAME}"
  subnet_id = "${SUBNET_ID}"
  associate_public_ip_address = "true"
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

  echo "Creating Ops Manager instance in AWS..."
  ./${CMD_PATH} apply
}

echo "Running deploy of OpsMgr VM task..."
main "${PWD}"
