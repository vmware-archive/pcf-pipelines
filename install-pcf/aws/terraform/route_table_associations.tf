# subnet associations for public subnet
resource "aws_route_table_association" "a_az1" {
    subnet_id = "${aws_subnet.PcfVpcPublicSubnet_az1.id}"
    route_table_id = "${aws_route_table.PublicSubnetRouteTable.id}"
}
resource "aws_route_table_association" "a_az2" {
    subnet_id = "${aws_subnet.PcfVpcPublicSubnet_az2.id}"
    route_table_id = "${aws_route_table.PublicSubnetRouteTable.id}"
}
resource "aws_route_table_association" "a_az3" {
    subnet_id = "${aws_subnet.PcfVpcPublicSubnet_az3.id}"
    route_table_id = "${aws_route_table.PublicSubnetRouteTable.id}"
}

# subnet associations for ERT subnet

resource "aws_route_table_association" "b_az1" {
    subnet_id = "${aws_subnet.PcfVpcErtSubnet_az1.id}"
    route_table_id = "${aws_route_table.PrivateSubnetRouteTable_az1.id}"
}

resource "aws_route_table_association" "x_az2" {
    subnet_id = "${aws_subnet.PcfVpcErtSubnet_az2.id}"
    route_table_id = "${aws_route_table.SubnetRouteTable_az2.id}"
}

resource "aws_route_table_association" "x_az3" {
    subnet_id = "${aws_subnet.PcfVpcErtSubnet_az3.id}"
    route_table_id = "${aws_route_table.SubnetRouteTable_az3.id}"
}

# subnet associations for RDS subnet

resource "aws_route_table_association" "c_az1" {
    subnet_id = "${aws_subnet.PcfVpcRdsSubnet_az1.id}"
    route_table_id = "${aws_route_table.PrivateSubnetRouteTable_az1.id}"
}
resource "aws_route_table_association" "y_az2" {
    subnet_id = "${aws_subnet.PcfVpcRdsSubnet_az2.id}"
    route_table_id = "${aws_route_table.SubnetRouteTable_az2.id}"
}
resource "aws_route_table_association" "y_az3" {
    subnet_id = "${aws_subnet.PcfVpcRdsSubnet_az3.id}"
    route_table_id = "${aws_route_table.SubnetRouteTable_az3.id}"
}

# subnet associations for services subnet

resource "aws_route_table_association" "d_az1" {
    subnet_id = "${aws_subnet.PcfVpcServicesSubnet_az1.id}"
    route_table_id = "${aws_route_table.PrivateSubnetRouteTable_az1.id}"
}

resource "aws_route_table_association" "z_az2" {
    subnet_id = "${aws_subnet.PcfVpcServicesSubnet_az2.id}"
    route_table_id = "${aws_route_table.SubnetRouteTable_az2.id}"
}
resource "aws_route_table_association" "z_az3" {
    subnet_id = "${aws_subnet.PcfVpcServicesSubnet_az3.id}"
    route_table_id = "${aws_route_table.SubnetRouteTable_az3.id}"
}
# subnet associations for dynamic services subnet

resource "aws_route_table_association" "dynamic_services_az1" {
    subnet_id = "${aws_subnet.PcfVpcDynamicServicesSubnet_az1.id}"
    route_table_id = "${aws_route_table.PrivateSubnetRouteTable_az1.id}"
}

resource "aws_route_table_association" "dynamic_services_az2" {
    subnet_id = "${aws_subnet.PcfVpcDynamicServicesSubnet_az2.id}"
    route_table_id = "${aws_route_table.SubnetRouteTable_az2.id}"
}
resource "aws_route_table_association" "dynamic_services_az3" {
    subnet_id = "${aws_subnet.PcfVpcDynamicServicesSubnet_az3.id}"
    route_table_id = "${aws_route_table.SubnetRouteTable_az3.id}"
}

# subnet associations for infrastructure subnet

resource "aws_route_table_association" "i_az1" {
    subnet_id = "${aws_subnet.PcfVpcInfraSubnet_az1.id}"
    route_table_id = "${aws_route_table.PrivateSubnetRouteTable_az1.id}"
}
