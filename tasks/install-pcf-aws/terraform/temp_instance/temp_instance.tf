resource "aws_instance" "temp_az1" {
    ami = "${var.amis_temp_instance["${var.aws_region}"]}"
    availability_zone = "${var.az1}"
    instance_type = "${var.temp_instance_type}"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.directorSG.id}"]
    subnet_id = "${aws_subnet.PcfVpcPublicSubnet_az1.id}"
    associate_public_ip_address = true

    provisioner "file" {
        source = "variables.tf"
        destination = "variables.tf"
        connection {
            type = "ssh"
	    user = "ubuntu"
            private_key = "${file("temp_instance_key.pem")}"
        }
    }
    provisioner "file" {
        source = "aws.tf"
        destination = "aws.tf"
        connection {
            type = "ssh"
	    user = "ubuntu"
            private_key = "${file("temp_instance_key.pem")}"
        }
    }
    provisioner "file" {
        source = "create_databases.tf_move"
        destination = "create_databases.tf"
        connection {
            type = "ssh"
	    user = "ubuntu"
            private_key = "${file("temp_instance_key.pem")}"
        }
    }
    provisioner "file" {
        source = "create_database.sh"
        destination = "create_database.sh"
        connection {
            type = "ssh"
	    user = "ubuntu"
            private_key = "${file("temp_instance_key.pem")}"
        }
    }
    provisioner "file" {
        source = "rds_input.txt"
        destination = "rds_input.txt"
        connection {
            type = "ssh"
	    user = "ubuntu"
            private_key = "${file("temp_instance_key.pem")}"
        }
    }
    provisioner "file" {
        source = "rds-terraform.tfstate"
        destination = "terraform.tfstate"
        connection {
            type = "ssh"
	    user = "ubuntu"
            private_key = "${file("temp_instance_key.pem")}"
        }
    }
    provisioner "file" {
        source = "terraform"
        destination = "terraform"
        connection {
            type = "ssh"
	    user = "ubuntu"
            private_key = "${file("temp_instance_key.pem")}"
        }
    }
/*
    provisioner "remote-exec" {
        inline = [
	  "source rds_input.txt",
          "chmod +x create_database.sh",
          "./create_database.sh"
        ]
        connection {
            type = "ssh"
            user = "ubuntu"
            private_key = "${file("temp_instance_key.pem")}"
        }
    }

*/
    tags {
        Name = "${var.environment}-TempInstance az1"
    }
}
