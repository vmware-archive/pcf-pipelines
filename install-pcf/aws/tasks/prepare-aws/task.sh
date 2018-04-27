#!/bin/bash

set -eu

echo "=============================================================================================="
echo "Collecting Terraform Variables from Deployed AWS Objects ...."
echo "=============================================================================================="

ami=$(cat ami/ami)

OPSMAN_ALLOW_SSH=0
OPSMAN_ALLOW_SSH_CIDR_LIST='["0.0.0.0/32"]'
if [[ -n "${OPSMAN_ALLOW_SSH_CIDR_RANGES// }" ]]; then
  OPSMAN_ALLOW_SSH=1
  OPSMAN_ALLOW_SSH_CIDR_LIST='["'${OPSMAN_ALLOW_SSH_CIDR_RANGES//\,/\"\,\"}'"]'
fi

OPSMAN_ALLOW_HTTPS=0
OPSMAN_ALLOW_HTTPS_CIDR_LIST='["0.0.0.0/32"]'
if [[ -n "${OPSMAN_ALLOW_HTTPS_CIDR_RANGES// }" ]]; then
  OPSMAN_ALLOW_HTTPS=1
  OPSMAN_ALLOW_HTTPS_CIDR_LIST='["'${OPSMAN_ALLOW_HTTPS_CIDR_RANGES//\,/\"\,\"}'"]'
fi

aws acm get-certificate --certificate-arn arn:aws:acm:us-west-2:473893145203:certificate/3c762430-0ffc-4523-bba4-7b02dd9f9b2b | jq .Certificate

echo "env_name=\"${TERRAFORM_PREFIX}\"" >> terraform-vars-output/terraform.tfvars
echo "access_key=\"${aws_access_key_id}\"" >> terraform-vars-output/terraform.tfvars
echo "secret_key=\"${aws_secret_access_key}\"" >> terraform-vars-output/terraform.tfvars
echo "region=\"${aws_region}\"" >> terraform-vars-output/terraform.tfvars
echo "availability_zones=\"[${aws_az1},${aws_az2},${aws_az3}]\"" >> terraform-vars-output/terraform.tfvars
echo "ops_manager_ami=\"${ami}\"" >> terraform-vars-output/terraform.tfvars
echo "dns_suffix=\"${pcf_ert_domain}\"" >> terraform-vars-output/terraform.tfvars
echo "vpc_cidr=\"${vpc_cidr}\"" >> terraform-vars-output/terraform.tfvars
echo "ssl_ca_cert=\"${ssl_ca_cert}\"" >> terraform-vars-output/terraform.tfvars
echo "ssl_ca_private_key=\"${ssl_ca_private_key}\"" >> terraform-vars-output/terraform.tfvars

#echo "db_master_username=\"${DB_MASTER_USERNAME}\"" >> terraform-vars-output/terraform.tfvars
#echo "db_master_password=\"${DB_MASTER_PASSWORD}\"" >> terraform-vars-output/terraform.tfvars
#echo "prefix=\"${TERRAFORM_PREFIX}\"" >> terraform-vars-output/terraform.tfvars
#echo "opsman_allow_ssh=\"${OPSMAN_ALLOW_SSH}\"" >> terraform-vars-output/terraform.tfvars
#echo "opsman_allow_ssh_cidr_ranges=\"${OPSMAN_ALLOW_SSH_CIDR_LIST}\"" >> terraform-vars-output/terraform.tfvars
#echo "opsman_allow_https=\"${OPSMAN_ALLOW_HTTPS}\"" >> terraform-vars-output/terraform.tfvars
#echo "opsman_allow_https_cidr_ranges=\"${OPSMAN_ALLOW_HTTPS_CIDR_LIST}\"" >> terraform-vars-output/terraform.tfvars
#echo "aws_key_name=\"${aws_key_name}\"" >> terraform-vars-output/terraform.tfvars
#echo "amis_nat=\"${amis_nat}\"" >> terraform-vars-output/terraform.tfvars
#echo "route53_zone_id=\"${route53_zone_id}\"" >> terraform-vars-output/terraform.tfvars
#echo "system_domain=\"${system_domain}\"" >> terraform-vars-output/terraform.tfvars
#echo "apps_domain=\"${apps_domain}\"" >> terraform-vars-output/terraform.tfvars
#echo "public_subnet_cidr_az1=\"${public_subnet_cidr_az1}\"" >> terraform-vars-output/terraform.tfvars
#echo "public_subnet_cidr_az2=\"${public_subnet_cidr_az2}\"" >> terraform-vars-output/terraform.tfvars
#echo "public_subnet_cidr_az3=\"${public_subnet_cidr_az3}\"" >> terraform-vars-output/terraform.tfvars
#echo "ert_subnet_cidr_az1=\"${ert_subnet_cidr_az1}\"" >> terraform-vars-output/terraform.tfvars
#echo "ert_subnet_cidr_az2=\"${ert_subnet_cidr_az2}\"" >> terraform-vars-output/terraform.tfvars
#echo "ert_subnet_cidr_az3=\"${ert_subnet_cidr_az3}\"" >> terraform-vars-output/terraform.tfvars
#echo "services_subnet_cidr_az1=\"${services_subnet_cidr_az1}\"" >> terraform-vars-output/terraform.tfvars
#echo "services_subnet_cidr_az2=\"${services_subnet_cidr_az2}\"" >> terraform-vars-output/terraform.tfvars
#echo "services_subnet_cidr_az3=\"${services_subnet_cidr_az3}\"" >> terraform-vars-output/terraform.tfvars
#echo "dynamic_services_subnet_cidr_az1=\"${dynamic_services_subnet_cidr_az1}\"" >> terraform-vars-output/terraform.tfvars
#echo "dynamic_services_subnet_cidr_az2=\"${dynamic_services_subnet_cidr_az2}\"" >> terraform-vars-output/terraform.tfvars
#echo "dynamic_services_subnet_cidr_az3=\"${dynamic_services_subnet_cidr_az3}\"" >> terraform-vars-output/terraform.tfvars
#echo "infra_subnet_cidr_az1=\"${infra_subnet_cidr_az1}\"" >> terraform-vars-output/terraform.tfvars
#echo "rds_subnet_cidr_az1=\"${rds_subnet_cidr_az1}\"" >> terraform-vars-output/terraform.tfvars
#echo "rds_subnet_cidr_az2=\"${rds_subnet_cidr_az2}\"" >> terraform-vars-output/terraform.tfvars
#echo "rds_subnet_cidr_az3=\"${rds_subnet_cidr_az3}\"" >> terraform-vars-output/terraform.tfvars
#echo "opsman_ip_az1=\"${opsman_ip_az1}\"" >> terraform-vars-output/terraform.tfvars
#echo "nat_ip_az1=\"${nat_ip_az1}\"" >> terraform-vars-output/terraform.tfvars
#echo "nat_ip_az2=\"${nat_ip_az2}\"" >> terraform-vars-output/terraform.tfvars
#echo "nat_ip_az3=\"${nat_ip_az3}\"" >> terraform-vars-output/terraform.tfvars

echo "=============================================================================================="
echo "Executing Terraform Plan ..."
echo "=============================================================================================="

terraform init "/home/vcap/app/terraforming-aws"

terraform plan \
  -var-file "terraform-vars-output/terraform.tfvars" \
  -state "terraform-state/terraform.tfstate" \
  -out terraform.tfplan \
  "/home/vcap/app/terraforming-aws"

echo "=============================================================================================="
echo "Executing Terraform Apply ..."
echo "=============================================================================================="

terraform apply \
  -state-out terraform-state-output/terraform.tfstate \
  terraform.tfplan
