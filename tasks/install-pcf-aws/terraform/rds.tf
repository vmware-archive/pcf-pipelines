resource "aws_db_subnet_group" "rds_subnet_group" {
    name = "${var.environment}-rds_subnet_group"
    subnet_ids = ["${aws_subnet.PcfVpcRdsSubnet_az1.id}", "${aws_subnet.PcfVpcRdsSubnet_az2.id}", "${aws_subnet.PcfVpcRdsSubnet_az3.id}"]
    tags {
        Name = "${var.environment} RDS DB subnet group"
    }
}
resource "aws_db_instance" "pcf_rds" {
    identifier              = "${var.environment}-pcf"
    allocated_storage       = 100
    engine                  = "mysql"
    engine_version          = "5.6.27"
    iops                    = 1000
    instance_class          = "${var.db_instance_type}"
    name                    = "bosh"
    username                = "${var.rds_db_username}"
    password                = "${var.rds_db_password}"
    db_subnet_group_name    = "${aws_db_subnet_group.rds_subnet_group.name}"
    parameter_group_name    = "default.mysql5.6"
    vpc_security_group_ids  = ["${aws_security_group.rdsSG.id}"]
    multi_az                = true
    backup_retention_period = 7
    apply_immediately       = true
}
