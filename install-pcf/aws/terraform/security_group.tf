/*
  Security Group Definitions
*/

/*
  Ops Manager Security group
*/
resource "aws_security_group" "directorSG" {
    name = "${var.prefix}-pcf_director_sg"
    description = "Allow incoming connections for Ops Manager."
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags {
        Name = "${var.prefix}-Ops Manager Director Security Group"
    }
}

resource "aws_security_group_rule" "allow_directorsg_ingress_default" {
    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["${var.vpc_cidr}"]
    security_group_id = "${aws_security_group.directorSG.id}"
}

resource "aws_security_group_rule" "allow_directorsg_egress_default" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.directorSG.id}"
}

resource "aws_security_group_rule" "allow_ssh" {
    count           = "${var.opsman_allow_ssh}"
    type            = "ingress"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = "${var.opsman_allow_ssh_cidr_ranges}"

    security_group_id = "${aws_security_group.directorSG.id}"
}

resource "aws_security_group_rule" "allow_https" {
    count           = "${var.opsman_allow_https}" 
    type            = "ingress"
    from_port       = 443 
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = "${var.opsman_allow_https_cidr_ranges}"

    security_group_id = "${aws_security_group.directorSG.id}"
}

/*
  RDS Security group
*/
resource "aws_security_group" "rdsSG" {
    name = "${var.prefix}-pcf_rds_sg"
    description = "Allow incoming connections for RDS."
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags {
        Name = "${var.prefix}-RDS Security Group"
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
    name = "${var.prefix}-pcf_vms_sg"
    description = "Allow connections between PCF VMs."
    vpc_id = "${aws_vpc.PcfVpc.id}"
    tags {
        Name = "${var.prefix}-PCF VMs Security Group"
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
