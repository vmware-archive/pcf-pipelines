/*
  Security Group Definitions
*/

/*
  Ops Manager Security group
*/
resource "aws_security_group" "directorSG" {
    name = "${var.environment}-pcf_director_sg"
    description = "Allow incoming connections for Ops Manager."
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags {
        Name = "${var.environment}-Ops Manager Director Security Group"
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
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

/*
  RDS Security group
*/
resource "aws_security_group" "rdsSG" {
    name = "${var.environment}-pcf_rds_sg"
    description = "Allow incoming connections for RDS."
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags {
        Name = "${var.environment}-RDS Security Group"
    }
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

}

/*
  PCF VMS Security group
*/
resource "aws_security_group" "pcfSG" {
    name = "${var.environment}-pcf_vms_sg"
    description = "Allow connections between PCF VMs."
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags {
        Name = "${var.environment}-PCF VMs Security Group"
    }
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}
