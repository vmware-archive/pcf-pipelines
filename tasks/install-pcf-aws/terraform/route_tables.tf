# Routing Tables for all subnets

resource "aws_route_table" "PublicSubnetRouteTable" {
    vpc_id = "${aws_vpc.PcfVpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.internetGw.id}"
    }

    tags {
        Name = "${var.prefix}-Public Subnet Route Table"
    }
}

# AZ1 Routing table
resource "aws_route_table" "PrivateSubnetRouteTable_az1" {
    vpc_id = "${aws_vpc.PcfVpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat_az1.id}"
    }

    tags {
        Name = "${var.prefix}-Private Subnet Route Table AZ1"
    }
}

# AZ2 Routing table
resource "aws_route_table" "SubnetRouteTable_az2" {
    vpc_id = "${aws_vpc.PcfVpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat_az2.id}"
    }

    tags {
        Name = "${var.prefix}-Private Subnet Route Table AZ2"
    }
}

# AZ3 Routing table
resource "aws_route_table" "SubnetRouteTable_az3" {
    vpc_id = "${aws_vpc.PcfVpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat_az3.id}"
    }

    tags {
        Name = "${var.prefix}-Private Subnet Route Table AZ3"
    }
}
