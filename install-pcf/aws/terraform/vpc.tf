/*
  For Region
*/
resource "aws_vpc" "PcfVpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags = "${merge(var.tags, map("Name", format("%s-terraform-pcf-vpc", var.prefix)))}"
}
resource "aws_internet_gateway" "internetGw" {
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags = "${merge(var.tags, map("Name", format("%s-internet-gateway", var.prefix)))}"
}

# 3. NAT instance setup
# 3.1 Security Group for NAT
resource "aws_security_group" "nat_instance_sg" {
    name = "${var.prefix}-nat_instance_sg"
    description = "${var.prefix} NAT Instance Security Group"
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags = "${merge(var.tags, map("Name", format("%s-NAT intance security group", var.prefix)))}"
    ingress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}
# 3.2 Create NAT instance
resource "aws_instance" "nat_az1" {
    ami = "${var.amis_nat}"
    availability_zone = "${var.aws_az1}"
    instance_type = "${var.nat_instance_type}"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.nat_instance_sg.id}"]
    subnet_id = "${aws_subnet.PcfVpcPublicSubnet_az1.id}"
    associate_public_ip_address = true
    source_dest_check = false
    private_ip = "${var.nat_ip_az1}"

    tags = "${merge(var.tags, map("Name", format("%s-Nat Instance az1", var.prefix)))}"
}

resource "aws_instance" "nat_az2" {
    ami = "${var.amis_nat}"
    availability_zone = "${var.aws_az2}"
    instance_type = "${var.nat_instance_type}"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.nat_instance_sg.id}"]
    subnet_id = "${aws_subnet.PcfVpcPublicSubnet_az2.id}"
    associate_public_ip_address = true
    source_dest_check = false
    private_ip = "${var.nat_ip_az2}"

    tags = "${merge(var.tags, map("Name", format("%s-Nat Instance az2", var.prefix)))}"
}

# NAT Insance
resource "aws_instance" "nat_az3" {
    ami = "${var.amis_nat}"
    availability_zone = "${var.aws_az3}"
    instance_type = "${var.nat_instance_type}"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.nat_instance_sg.id}"]
    subnet_id = "${aws_subnet.PcfVpcPublicSubnet_az3.id}"
    associate_public_ip_address = true
    source_dest_check = false
    private_ip = "${var.nat_ip_az3}"

    tags = "${merge(var.tags, map("Name", format("%s-Nat Instance az3", var.prefix)))}"
}
}
