# Create OpsMan instance
resource "aws_instance" "opsmman_az1" {
    ami = "${var.opsman_ami}"
    availability_zone = "${var.aws_az1}"
    instance_type = "${var.opsman_instance_type}"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.directorSG.id}"]
    subnet_id = "${aws_subnet.PcfVpcPublicSubnet_az1.id}"
    private_ip = "${var.opsman_ip_az1}"
    root_block_device {
        volume_size = 100
    }
    tags = "${merge(var.tags, map("Name", format("%s-OpsMan az1", var.prefix)))}"
}

resource "aws_eip" "opsman" {
  instance = "${aws_instance.opsmman_az1.id}"
  vpc      = true
}
