/*
  For First availability zone
*/

# 1. Create Public Subnet
resource "aws_subnet" "PcfVpcPublicSubnet" {
  count  = "${length(data.aws_availability_zones.az.names)}"
  vpc_id = "${aws_vpc.PcfVpc.id}"

  cidr_block        = "${cidrsubnet(var.vpc_cidr, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.az.names[count.index]}"

  tags {
    Name = "${var.prefix}-PcfVpc Public Subnet ${data.aws_availability_zones.az.names[count.index]}"
  }
}

# 2. Create Private Subnets
# 2.1 ERT
resource "aws_subnet" "PcfVpcErtSubnet" {
  count  = "${length(data.aws_availability_zones.az.names)}"
  vpc_id = "${aws_vpc.PcfVpc.id}"

  cidr_block        = "${cidrsubnet(var.vpc_cidr, 4, count.index+4)}"
  availability_zone = "${data.aws_availability_zones.az.names[count.index]}"

  tags {
    Name = "${var.prefix}-PcfVpc Ert Subnet ${data.aws_availability_zones.az.names[count.index]}"
  }
}

# 2.2 RDS
resource "aws_subnet" "PcfVpcRdsSubnet" {
  count  = "${length(data.aws_availability_zones.az.names)}"
  vpc_id = "${aws_vpc.PcfVpc.id}"

  cidr_block        = "${cidrsubnet(var.vpc_cidr, 8, count.index+7)}"
  availability_zone = "${data.aws_availability_zones.az.names[count.index]}"

  tags {
    Name = "${var.prefix}-PcfVpc Rds Subnet ${data.aws_availability_zones.az.names[count.index]}"
  }
}

# 2.3 Services
resource "aws_subnet" "PcfVpcServicesSubnet" {
  count  = "${length(data.aws_availability_zones.az.names)}"
  vpc_id = "${aws_vpc.PcfVpc.id}"

  cidr_block        = "${cidrsubnet(var.vpc_cidr, 4, count.index+10)}"
  availability_zone = "${data.aws_availability_zones.az.names[count.index]}"

  tags {
    Name = "${var.prefix}-PcfVpc Services Subnet ${data.aws_availability_zones.az.names[count.index]}"
  }
}

# 2.4 Dynamic Services
resource "aws_subnet" "PcfVpcDynamicServicesSubnet" {
  count  = "${length(data.aws_availability_zones.az.names)}"
  vpc_id = "${aws_vpc.PcfVpc.id}"

  cidr_block        = "${cidrsubnet(var.vpc_cidr, 4, count.index+13)}"
  availability_zone = "${data.aws_availability_zones.az.names[count.index]}"

  tags {
    Name = "${var.prefix}-PcfVpc Dynamic Services Subnet ${data.aws_availability_zones.az.names[count.index]}"
  }
}

# Infrastructure network  - For bosh director
resource "aws_subnet" "PcfVpcInfraSubnet" {
  count  = "${length(data.aws_availability_zones.az.names)}"
  vpc_id = "${aws_vpc.PcfVpc.id}"

  cidr_block        = "${cidrsubnet(var.vpc_cidr, 8, count.index+16)}"
  availability_zone = "${data.aws_availability_zones.az.names[count.index]}"

  tags {
    Name = "${var.prefix}-PcfVpc Infrastructure Subnet ${data.aws_availability_zones.az.names[count.index]}"
  }
}
