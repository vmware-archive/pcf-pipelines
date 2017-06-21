/*
  Security Group Definitions for Elastic Load Balancers
*/

/*
  Elb PcfHttpElb  Security group
*/
resource "aws_security_group" "PcfHttpElbSg" {
    name = "${var.prefix}-pcf_PcfHttpElb_sg"
    description = "Allow incoming connections for PcfHttpElb Elb."
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags {
        Name = "${var.prefix}-PcfHttpElb Security Group"
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 4443
        to_port = 4443
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "PcfSshElbSg" {
    name = "${var.prefix}-pcf_PcfSshElb_sg"
    description = "Allow incoming connections for PcfSshElb Elb."
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags {
        Name = "${var.prefix}-PcfSshElb Security Group"
    }
    ingress {
        from_port = 2222
        to_port = 2222
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_security_group" "PcfTcpElbSg" {
    name = "${var.prefix}-pcf_PcfTcoElb_sg"
    description = "Allow incoming connections for PcfTcpElb Elb."
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags {
        Name = "${var.prefix}-PcfTcpElb Security Group"
    }
    ingress {
        from_port = 1024
        to_port = 1123
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}
