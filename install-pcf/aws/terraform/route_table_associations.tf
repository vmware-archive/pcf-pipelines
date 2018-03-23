# subnet associations for public subnet
resource "aws_route_table_association" "PcfVpcPublic" {
  count          = "${length(data.aws_availability_zones.az.names)}"
  subnet_id      = "${element(aws_subnet.PcfVpcPublicSubnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.PublicSubnetRouteTable.*.id, count.index)}"
}

# subnet associations for ERT subnet
resource "aws_route_table_association" "PcfVpcErt" {
  count          = "${length(data.aws_availability_zones.az.names)}"
  subnet_id      = "${element(aws_subnet.PcfVpcErtSubnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.PrivateSubnetRouteTable.*.id, count.index)}"
}

# subnet associations for RDS subnet
resource "aws_route_table_association" "PcfVpcRds" {
  count          = "${length(data.aws_availability_zones.az.names)}"
  subnet_id      = "${element(aws_subnet.PcfVpcRdsSubnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.PrivateSubnetRouteTable.*.id, count.index)}"
}

# subnet associations for services subnet
resource "aws_route_table_association" "PcfVpcServices" {
  count          = "${length(data.aws_availability_zones.az.names)}"
  subnet_id      = "${element(aws_subnet.PcfVpcServicesSubnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.PrivateSubnetRouteTable.*.id, count.index)}"
}

# subnet associations for dynamic services subnet
resource "aws_route_table_association" "PcfVpcDynamicServices" {
  count          = "${length(data.aws_availability_zones.az.names)}"
  subnet_id      = "${element(aws_subnet.PcfVpcDynamicServicesSubnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.PrivateSubnetRouteTable.*.id, count.index)}"
}

# subnet associations for infrastructure subnet
resource "aws_route_table_association" "PcfVpcInfra" {
  count          = "${length(data.aws_availability_zones.az.names)}"
  subnet_id      = "${element(aws_subnet.PcfVpcInfraSubnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.PrivateSubnetRouteTable.*.id, count.index)}"
}
