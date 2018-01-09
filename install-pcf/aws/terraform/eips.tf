resource "aws_eip" "nat_az1" {
  instance = "${aws_instance.nat_az1.id}"
  vpc  = true
}

resource "aws_eip" "nat_az2" {
  instance = "${aws_instance.nat_az2.id}"
  vpc  = true
}

resource "aws_eip" "nat_az3" {
  instance = "${aws_instance.nat_az3.id}"
  vpc  = true
}
