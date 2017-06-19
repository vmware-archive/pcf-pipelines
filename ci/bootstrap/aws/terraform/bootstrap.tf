resource "random_pet" "server" {
  length = "2"
}

resource "aws_s3_bucket" "terraform" {
  bucket = "aws-bootstrap-terraform-${random_pet.server.id}"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_route53_zone" "pcf-zone" {
  name = "${random_pet.server.id}.${var.route53_domain}"
}

resource "aws_route53_record" "pcf-zone-ns-record" {
  zone_id = "${var.route53_zone_id}"
  name    = "${aws_route53_zone.pcf-zone.name}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.pcf-zone.name_servers.0}",
    "${aws_route53_zone.pcf-zone.name_servers.1}",
    "${aws_route53_zone.pcf-zone.name_servers.2}",
    "${aws_route53_zone.pcf-zone.name_servers.3}",
  ]
}

resource "tls_private_key" "opsman" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "opsman" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.opsman.private_key_pem}"

  subject {
    common_name  = "${aws_route53_zone.pcf-zone.name}"
    organization = "Customer[0]"
  }

  validity_period_hours = 2160

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_private_key" "opsman_key_pair" {
  algorithm = "RSA"
}

resource "aws_key_pair" "opsman" {
  key_name   = "${random_pet.server.id}-opsman"
  public_key = "${tls_private_key.opsman_key_pair.public_key_openssh}"
}
