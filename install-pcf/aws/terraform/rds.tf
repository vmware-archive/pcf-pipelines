resource "aws_db_subnet_group" "rds_subnet_group" {
    name = "${var.prefix}-rds_subnet_group"
    subnet_ids = ["${aws_subnet.PcfVpcRdsSubnet_az1.id}", "${aws_subnet.PcfVpcRdsSubnet_az2.id}", "${aws_subnet.PcfVpcRdsSubnet_az3.id}"]
    tags {
        Name = "${var.prefix} RDS DB subnet group"
    }
}
resource "aws_db_instance" "pcf_rds" {
    identifier              = "${var.prefix}-pcf"
    allocated_storage       = 100
    engine                  = "mariadb"
    engine_version          = "10.1.19"
    iops                    = 1000
    instance_class          = "${var.db_instance_type}"
    name                    = "bosh"
    username                = "${var.db_master_username}"
    password                = "${var.db_master_password}"
    db_subnet_group_name    = "${aws_db_subnet_group.rds_subnet_group.name}"
    parameter_group_name    = "default.mariadb10.1"
    vpc_security_group_ids  = ["${aws_security_group.rdsSG.id}"]
    multi_az                = true
    backup_retention_period = 7
    apply_immediately       = true
    skip_final_snapshot     = true
}
