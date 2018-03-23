# Routing Tables for all subnets

resource "aws_route_table" "PublicSubnetRouteTable" {
  count  = "${length(data.aws_availability_zones.az.names)}"
  vpc_id = "${aws_vpc.PcfVpc.id}"

  tags {
    Name = "${var.prefix}-Public Subnet Route Table ${data.aws_availability_zones.az.names[count.index]}"
  }
}

# AZ1 Routing table
resource "aws_route_table" "PrivateSubnetRouteTable" {
  count  = "${length(data.aws_availability_zones.az.names)}"
  vpc_id = "${aws_vpc.PcfVpc.id}"

  tags {
    Name = "${var.prefix}-Private Subnet Route Table ${data.aws_availability_zones.az.names[count.index]}"
  }
}

resource "aws_route" "PublicInternetGw" {
  count                  = "${length(data.aws_availability_zones.az.names)}"
  route_table_id         = "${element(aws_route_table.PublicSubnetRouteTable.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.internetGw.id}"
}

resource "aws_route" "PrivateNATGw" {
  count                  = "${length(data.aws_availability_zones.az.names)}"
  route_table_id         = "${element(aws_route_table.PrivateSubnetRouteTable.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${element(aws_nat_gateway.natGw.*.id, count.index)}"
}
