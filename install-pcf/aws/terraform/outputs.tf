output "prefix" {
  value = "${var.prefix}"
}

output "region" {
  value = "${var.aws_region}"
}

output "vpc_id" {
  value = "${aws_vpc.PcfVpc.id}"
}

output "vpc_cidr" {
  value = "${var.vpc_cidr}"
}

output "pcf_security_group" {
  value = "${aws_security_group.pcfSG.id}"
}

output "opsman_eip" {
  value = "${aws_eip.opsman.public_ip}"
}

output "opsman_identifier" {
  value = "${aws_instance.opsmman.tags.Name}"
}

# s3 buckets
output "s3_pcf_bosh" {
  value = "${aws_s3_bucket.bosh.bucket}"
}

output "s3_buildpacks" {
  value = "${aws_s3_bucket.buildpacks.bucket}"
}

output "s3_pcf_droplets" {
  value = "${aws_s3_bucket.droplets.bucket}"
}

output "s3_pcf_packages" {
  value = "${aws_s3_bucket.packages.bucket}"
}

output "s3_pcf_resources" {
  value = "${aws_s3_bucket.resources.bucket}"
}

# DNS
output "dns" {
  value = "${cidrhost("${var.vpc_cidr}", 2)}"
}

# AZ1

output "public_subnet_cidr_az1" {
  value = "${element(aws_subnet.PcfVpcPublicSubnet.*.cidr_block, 1)}"
}

output "ert_subnet_cidr_az1" {
  value = "${element(aws_subnet.PcfVpcErtSubnet.*.cidr_block, 1)}"
}

output "ert_subnet_gw_az1" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcErtSubnet.*.cidr_block, 1)}", 1)}"
}

output "rds_subnet_cidr_az1" {
  value = "${element(aws_subnet.PcfVpcRdsSubnet.*.cidr_block, 1)}"
}

output "services_subnet_cidr_az1" {
  value = "${element(aws_subnet.PcfVpcServicesSubnet.*.cidr_block, 1)}"
}

output "services_subnet_gw_az1" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcServicesSubnet.*.cidr_block, 1)}", 1)}"
}

output "dynamic_services_subnet_cidr_az1" {
  value = "${element(aws_subnet.PcfVpcDynamicServicesSubnet.*.cidr_block, 1)}"
}

output "dynamic_services_subnet_gw_az1" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcDynamicServicesSubnet.*.cidr_block, 1)}", 1)}"
}

output "infra_subnet_cidr_az1" {
  value = "${element(aws_subnet.PcfVpcInfraSubnet.*.cidr_block, 1)}"
}

output "infra_subnet_gw_az1" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcInfraSubnet.*.cidr_block, 1)}", 1)}"
}

# AZ2

output "public_subnet_cidr_az2" {
  value = "${element(aws_subnet.PcfVpcPublicSubnet.*.cidr_block, 2)}"
}

output "ert_subnet_cidr_az2" {
  value = "${element(aws_subnet.PcfVpcErtSubnet.*.cidr_block, 2)}"
}

output "ert_subnet_gw_az2" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcErtSubnet.*.cidr_block, 2)}", 2)}"
}

output "rds_subnet_cidr_az2" {
  value = "${element(aws_subnet.PcfVpcRdsSubnet.*.cidr_block, 2)}"
}

output "services_subnet_cidr_az2" {
  value = "${element(aws_subnet.PcfVpcServicesSubnet.*.cidr_block, 2)}"
}

output "services_subnet_gw_az2" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcServicesSubnet.*.cidr_block, 2)}", 2)}"
}

output "dynamic_services_subnet_cidr_az2" {
  value = "${element(aws_subnet.PcfVpcDynamicServicesSubnet.*.cidr_block, 2)}"
}

output "dynamic_services_subnet_gw_az2" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcDynamicServicesSubnet.*.cidr_block, 2)}", 2)}"
}

output "infra_subnet_cidr_az2" {
  value = "${element(aws_subnet.PcfVpcInfraSubnet.*.cidr_block, 2)}"
}

output "infra_subnet_gw_az2" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcInfraSubnet.*.cidr_block, 2)}", 2)}"
}

# AZ3

output "public_subnet_cidr_az3" {
  value = "${element(aws_subnet.PcfVpcPublicSubnet.*.cidr_block, 3)}"
}

output "ert_subnet_cidr_az3" {
  value = "${element(aws_subnet.PcfVpcErtSubnet.*.cidr_block, 3)}"
}

output "ert_subnet_gw_az3" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcErtSubnet.*.cidr_block, 3)}", 3)}"
}

output "rds_subnet_cidr_az3" {
  value = "${element(aws_subnet.PcfVpcRdsSubnet.*.cidr_block, 3)}"
}

output "services_subnet_cidr_az3" {
  value = "${element(aws_subnet.PcfVpcServicesSubnet.*.cidr_block, 3)}"
}

output "services_subnet_gw_az3" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcServicesSubnet.*.cidr_block, 3)}", 3)}"
}

output "dynamic_services_subnet_cidr_az3" {
  value = "${element(aws_subnet.PcfVpcDynamicServicesSubnet.*.cidr_block, 3)}"
}

output "dynamic_services_subnet_gw_az3" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcDynamicServicesSubnet.*.cidr_block, 3)}", 3)}"
}

output "infra_subnet_cidr_az3" {
  value = "${element(aws_subnet.PcfVpcInfraSubnet.*.cidr_block, 3)}"
}

output "infra_subnet_gw_az3" {
  value = "${cidrhost("${element(aws_subnet.PcfVpcInfraSubnet.*.cidr_block, 3)}", 3)}"
}

# RDS info

output "db_host" {
  value = "${aws_db_instance.pcf_rds.address}"
}

output "db_port" {
  value = "${aws_db_instance.pcf_rds.port}"
}

output "db_username" {
  value = "${aws_db_instance.pcf_rds.username}"
}

output "db_password" {
  value = "${aws_db_instance.pcf_rds.password}"
}

output "db_database" {
  value = "${aws_db_instance.pcf_rds.name}"
}
