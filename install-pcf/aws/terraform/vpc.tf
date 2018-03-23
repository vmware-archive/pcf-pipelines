/*
  For Region
*/

data "aws_availability_zones" "az" {}

resource "aws_vpc" "PcfVpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "${var.prefix}-terraform-pcf-vpc"
  }
}

resource "aws_internet_gateway" "internetGw" {
  vpc_id = "${aws_vpc.PcfVpc.id}"

  tags {
    Name = "${var.prefix}-internet-gateway"
  }
}

# 3. NAT instance setup
# 3.2 Create NAT instance
resource "aws_eip" "nat" {
  count = "${length(data.aws_availability_zones.az.names)}"
  vpc   = true
}

resource "aws_nat_gateway" "natGw" {
  count         = "${length(data.aws_availability_zones.az.names)}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.PcfVpcPublicSubnet.*.id, count.index)}"

  tags {
    Name = "${var.prefix}-nat-gateway-${data.aws_availability_zones.az.names[count.index]}"
  }
}
