# Create OpsMan instance
resource "aws_instance" "opsmman" {
  count                  = 1
  ami                    = "${var.opsman_ami}"
  availability_zone      = "${data.aws_availability_zones.az.names[count.index]}"
  instance_type          = "${var.opsman_instance_type}"
  key_name               = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.directorSG.id}"]
  subnet_id              = "${element(aws_subnet.PcfVpcPublicSubnet.*.id, count.index)}"

  root_block_device {
    volume_size = 100
  }

  tags {
    Name = "${var.prefix}-OpsMan az1"
  }
}

resource "aws_eip" "opsman" {
  instance = "${aws_instance.opsmman.id}"
  vpc      = true
}
