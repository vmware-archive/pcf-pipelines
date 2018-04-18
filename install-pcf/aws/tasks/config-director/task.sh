#!/bin/bash

set -eu

aws_access_key_id=`terraform state show -state terraform-state/terraform.tfstate aws_iam_access_key.pcf_iam_user_access_key | grep ^id | awk '{print $3}'`
aws_secret_access_key=`terraform state show -state terraform-state/terraform.tfstate aws_iam_access_key.pcf_iam_user_access_key | grep ^secret | awk '{print $3}'`
rds_password=`terraform state show -state terraform-state/terraform.tfstate aws_db_instance.pcf_rds | grep ^password | awk '{print $3}'`

while read -r line
do
  `echo "$line" | awk '{print "export "$1"="$3}'`
done < <(terraform output -state terraform-state/terraform.tfstate)


set +e
read -r -d '' iaas_configuration <<EOF
{
  "access_key_id": "$aws_access_key_id",
  "secret_access_key": "$aws_secret_access_key",
  "vpc_id": "$vpc_id",
  "security_group": "$pcf_security_group",
  "key_pair_name": "$AWS_KEY_NAME",
  "ssh_private_key": "",
  "region": "$AWS_REGION",
  "encrypted": false
}
EOF

read -r -d '' director_configuration <<EOF
{
  "ntp_servers_string": "0.amazon.pool.ntp.org,1.amazon.pool.ntp.org,2.amazon.pool.ntp.org,3.amazon.pool.ntp.org",
  "resurrector_enabled": true,
  "max_threads": 30,
  "database_type": "external",
  "external_database_options": {
    "host": "$db_host",
    "port": 3306,
    "user": "$db_username",
    "password": "$rds_password",
    "database": "$db_database"
  },
  "blobstore_type": "s3",
  "s3_blobstore_options": {
    "endpoint": "$S3_ENDPOINT",
    "bucket_name": "$s3_pcf_bosh",
    "access_key": "$aws_access_key_id",
    "secret_key": "$aws_secret_access_key",
    "signature_version": "4",
    "region": "$AWS_REGION"
  }
}
EOF

resource_configuration=$(cat <<-EOF
{
  "director": {
    "instance_type": {
      "id": "m4.large"
    }
  }
}
EOF
)

read -r -d '' az_configuration <<EOF
[
    { "name": "$az1" },
    { "name": "$az2" },
    { "name": "$az3" }
]
EOF

read -r -d '' networks_configuration <<EOF
{
  "icmp_checks_enabled": false,
  "networks": [
    {
      "name": "deployment",
      "service_network": false,
      "subnets": [
        {
          "iaas_identifier": "$ert_subnet_id_az1",
          "cidr": "$ert_subnet_cidr_az1",
          "reserved_ip_ranges": "$ert_subnet_reserved_ranges_z1",
          "dns": "$dns",
          "gateway": "$ert_subnet_gw_az1",
          "availability_zone_names": ["$az1"]
        },
        {
          "iaas_identifier": "$ert_subnet_id_az2",
          "cidr": "$ert_subnet_cidr_az2",
          "reserved_ip_ranges": "$ert_subnet_reserved_ranges_z2",
          "dns": "$dns",
          "gateway": "$ert_subnet_gw_az2",
          "availability_zone_names": ["$az2"]
        },
        {
          "iaas_identifier": "$ert_subnet_id_az3",
          "cidr": "$ert_subnet_cidr_az3",
          "reserved_ip_ranges": "$ert_subnet_reserved_ranges_z3",
          "dns": "$dns",
          "gateway": "$ert_subnet_gw_az3",
          "availability_zone_names": ["$az3"]
        }
      ]
    },
    {
      "name": "infrastructure",
      "service_network": false,
      "subnets": [
        {
          "iaas_identifier": "$infra_subnet_id_az1",
          "cidr": "$infra_subnet_cidr_az1",
          "reserved_ip_ranges": "$infra_subnet_reserved_ranges_z1",
          "dns": "$dns",
          "gateway": "$infra_subnet_gw_az1",
          "availability_zone_names": ["$az1"]
        }
      ]
    },
    {
      "name": "services",
      "service_network": false,
      "subnets": [
        {
          "iaas_identifier": "$services_subnet_id_az1",
          "cidr": "$services_subnet_cidr_az1",
          "reserved_ip_ranges": "$services_subnet_reserved_ranges_z1",
          "dns": "$dns",
          "gateway": "$services_subnet_gw_az1",
          "availability_zone_names": ["$az1"]
        },
        {
          "iaas_identifier": "$services_subnet_id_az2",
          "cidr": "$services_subnet_cidr_az2",
          "reserved_ip_ranges": "$services_subnet_reserved_ranges_z2",
          "dns": "$dns",
          "gateway": "$services_subnet_gw_az2",
          "availability_zone_names": ["$az2"]
        },
        {
          "iaas_identifier": "$services_subnet_id_az3",
          "cidr": "$services_subnet_cidr_az3",
          "reserved_ip_ranges": "$services_subnet_reserved_ranges_z3",
          "dns": "$dns",
          "gateway": "$services_subnet_gw_az3",
          "availability_zone_names": ["$az3"]
        }
      ]
    },
    {
      "name": "dynamic-services",
      "service_network": true,
      "subnets": [
        {
          "iaas_identifier": "$dynamic_services_subnet_id_az1",
          "cidr": "$dynamic_services_subnet_cidr_az1",
          "reserved_ip_ranges": "$dynamic_services_subnet_reserved_ranges_z1",
          "dns": "$dns",
          "gateway": "$dynamic_services_subnet_gw_az1",
          "availability_zone_names": ["$az1"]
        },
        {
          "iaas_identifier": "$dynamic_services_subnet_id_az2",
          "cidr": "$dynamic_services_subnet_cidr_az2",
          "reserved_ip_ranges": "$dynamic_services_subnet_reserved_ranges_z2",
          "dns": "$dns",
          "gateway": "$dynamic_services_subnet_gw_az2",
          "availability_zone_names": ["$az2"]
        },
        {
          "iaas_identifier": "$dynamic_services_subnet_id_az3",
          "cidr": "$dynamic_services_subnet_cidr_az3",
          "reserved_ip_ranges": "$dynamic_services_subnet_reserved_ranges_z3",
          "dns": "$dns",
          "gateway": "$dynamic_services_subnet_gw_az3",
          "availability_zone_names": ["$az3"]
        }
      ]
    }
  ]
}
EOF

read -r -d '' network_assignment <<EOF
{
  "singleton_availability_zone": {
    "name": "$az1"
   },
  "network": {
    "name": "infrastructure"
  }
}
EOF

read -r -d '' security_configuration <<EOF
{
  "trusted_certificates": "",
  "vm_password_type": "generate"
}
EOF
set -e

iaas_configuration=$(echo "$iaas_configuration" |jq --arg ssh_private_key "$PEM" '.ssh_private_key = $ssh_private_key')

security_configuration=$(
  echo "$security_configuration" |
  jq --arg certs "$TRUSTED_CERTIFICATES" '.trusted_certificates = $certs'
)

jsons=(
  "$iaas_configuration"
  "$director_configuration"
  "$az_configuration"
  "$networks_configuration"
  "$network_assignment"
  "$security_configuration"
  "$resource_configuration"
)

for json in "${jsons[@]}"; do
  # ensure JSON is valid
  echo "$json" | jq '.'
done

om-linux \
  --target https://${OPSMAN_DOMAIN_OR_IP_ADDRESS} \
  --skip-ssl-validation \
  --username "$OPSMAN_USER" \
  --password "$OPSMAN_PASSWORD" \
  configure-director \
  --iaas-configuration "$iaas_configuration" \
  --director-configuration "$director_configuration" \
  --az-configuration "$az_configuration" \
  --networks-configuration "$networks_configuration" \
  --network-assignment "$network_assignment" \
  --security-configuration "$security_configuration" \
  --resource-configuration "$resource_configuration"
