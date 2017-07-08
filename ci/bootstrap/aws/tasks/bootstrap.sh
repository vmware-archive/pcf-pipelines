set -eu

function output {
  terraform output -state terraform.tfstate $1
}

terraform plan \
  -var aws_access_key_id=$AWS_ACCESS_KEY_ID \
  -var aws_secret_access_key="$AWS_SECRET_ACCESS_KEY" \
  -var route53_domain=$ROUTE53_DOMAIN \
  -var route53_zone_id=$ROUTE53_ZONE_ID \
  -out terraform.tfplan \
  pcf-pipelines/ci/bootstrap/aws/terraform

terraform apply -state-out terraform.tfstate terraform.tfplan

ert_domain=$(output domain)
prefix=$(output prefix)

aws s3 cp terraform.tfstate "s3://${TERRAFORM_STATEFILES_BUCKET}/$prefix-terraform.tfstate"

echo $PIVNET_TOKEN > /dev/null
echo $MYSQL_MONITOR_EMAIL > /dev/null

cat > params.yml <<EOF
S3_OUTPUT_BUCKET: $(output s3_bucket)
ERT_DOMAIN: $ert_domain
OPSMAN_URI: opsman.$ert_domain
ROUTE_53_ZONE_ID: $(output zone_id)
TF_VAR_aws_key_name: $(output opsman_key_pair_name)
terraform_prefix: $prefix
pivnet_token: $PIVNET_TOKEN

opsman_major_minor_version: ^1\.11\..*$
ert_major_minor_version: ^1\.11\..*$

OPSMAN_USER: pcfadmin
OPSMAN_PASSWORD: $(output opsman_password)

db_master_username: root
db_master_password: $(output db_master_password)

db_app_usage_service_username: appusageservice
db_app_usage_service_password: $(output db_app_usage_service_password)
db_autoscale_username: autoscale
db_autoscale_password: $(output db_autoscale_password)
db_diego_username: diego
db_diego_password: $(output db_diego_password)
db_notifications_username: notifications
db_notifications_password: $(output db_notifications_password)
db_routing_username: routing
db_routing_password: $(output db_routing_password)
db_uaa_username: uaa
db_uaa_password: $(output db_uaa_password)
db_ccdb_username: ccdb
db_ccdb_password: $(output db_ccdb_password)
db_accountdb_username: accountdb
db_accountdb_password: $(output db_accountdb_password)
db_networkpolicyserverdb_username: netpolicyserver
db_networkpolicyserverdb_password: $(output db_networkpolicyserverdb_password)
db_nfsvolumedb_username: nfsvolume
db_nfsvolumedb_password: $(output db_nfsvolumedb_password)
db_locket_username: locket
db_locket_password: $(output db_locket_password)
db_silk_username: silk
db_silk_password: $(output db_silk_password)

TF_VAR_aws_access_key: $(output aws_access_key_id)
TF_VAR_aws_secret_key: $(output aws_secret_access_key)
mysql_monitor_recipient_email: $MYSQL_MONITOR_EMAIL

TF_VAR_amis_nat: ami-258e1f33
TF_VAR_aws_region: us-east-1
TF_VAR_az1: us-east-1a
TF_VAR_az2: us-east-1b
TF_VAR_az3: us-east-1d

S3_ENDPOINT: https://s3.amazonaws.com

ERT_SSL_CERT:
ERT_SSL_KEY:

mysql_backups: disable
ert_errands_to_disable: push-apps-manager,notifications,notifications-ui,push-pivotal-account,autoscaling,autoscaling-register-broker,nfsbrokerpush

OPSMAN_ALLOW_ACCESS: true
TF_VAR_opsman_allow_cidr: '["0.0.0.0/0"]'

mysql_backups_scp_server:
mysql_backups_scp_port:
mysql_backups_scp_user:
mysql_backups_scp_key:
mysql_backups_scp_destination:
mysql_backups_scp_cron_schedule:

mysql_backups_s3_endpoint_url:
mysql_backups_s3_bucket_name:
mysql_backups_s3_bucket_path:
mysql_backups_s3_access_key_id:
mysql_backups_s3_secret_access_key:
mysql_backups_s3_cron_schedule:

TF_VAR_vpc_cidr: 192.168.0.0/16
TF_VAR_public_subnet_cidr_az1: 192.168.0.0/24
TF_VAR_public_subnet_cidr_az2: 192.168.1.0/24
TF_VAR_public_subnet_cidr_az3: 192.168.2.0/24
TF_VAR_ert_subnet_cidr_az1: 192.168.16.0/20
ert_subnet_reserved_ranges_z1: 192.168.16.0 - 192.168.16.10
TF_VAR_ert_subnet_cidr_az2: 192.168.32.0/20
ert_subnet_reserved_ranges_z2: 192.168.32.0 - 192.168.32.10
TF_VAR_ert_subnet_cidr_az3: 192.168.48.0/20
ert_subnet_reserved_ranges_z3: 192.168.48.0 - 192.168.48.10
TF_VAR_services_subnet_cidr_az1: 192.168.64.0/20
services_subnet_reserved_ranges_z1: 192.168.64.0 - 192.168.64.10
TF_VAR_services_subnet_cidr_az2: 192.168.80.0/20
services_subnet_reserved_ranges_z2: 192.168.80.0 - 192.168.80.10
TF_VAR_services_subnet_cidr_az3: 192.168.96.0/20
services_subnet_reserved_ranges_z3: 192.168.96.0 - 192.168.96.10
TF_VAR_infra_subnet_cidr_az1: 192.168.6.0/24
infra_subnet_reserved_ranges_z1: 192.168.6.0 - 192.168.6.10
TF_VAR_rds_subnet_cidr_az1: 192.168.3.0/24
TF_VAR_rds_subnet_cidr_az2: 192.168.4.0/24
TF_VAR_rds_subnet_cidr_az3: 192.168.5.0/24
TF_VAR_opsman_ip_az1: 192.168.0.7
TF_VAR_nat_ip_az1: 192.168.0.6
TF_VAR_nat_ip_az2: 192.168.1.6
TF_VAR_nat_ip_az3: 192.168.2.6
EOF

IFS=$'\n'

echo "PEM: |" >> params.yml
for line in $(output opsman_key_pair_private_key); do
  echo "  $line" >> params.yml
done

echo "director_certificates: |" >> params.yml
for line in $(output opsman_certificate); do
  echo "  $line" >> params.yml
done

cat params.yml
