locals {
  is_alternate = "${var.aws_alternate_region != ""}"
}

resource "aws_route53_record" "opsman" {
  count = "${local.is_alternate ? 0 : 1}"
  zone_id = "${var.route53_zone_id}"
  name = "opsman"
  type = "A"
  ttl = "900"
  records = ["${aws_eip.opsman.public_ip}"]
}

resource "aws_route53_record" "apps_wild_card" {
  count = "${local.is_alternate ? 0 : 1}"
  zone_id = "${var.route53_zone_id}"
  name = "*.${element(split(".", var.apps_domain), 0)}"
  type = "CNAME"
  ttl = "900"
  records = ["${aws_elb.PcfHttpElb.dns_name}"]
}

resource "aws_route53_record" "system_wild_card" {
  count = "${local.is_alternate ? 0 : 1}"
  zone_id = "${var.route53_zone_id}"
  name = "*.${element(split(".", var.system_domain), 0)}"
  type = "CNAME"
  ttl = "900"
  records = ["${aws_elb.PcfHttpElb.dns_name}"]
}

resource "aws_route53_record" "ssh" {
  count = "${local.is_alternate ? 0 : 1}"
  zone_id = "${var.route53_zone_id}"
  name = "ssh.${element(split(".", var.system_domain), 0)}"
  type = "CNAME"
  ttl = "900"
  records = ["${aws_elb.PcfSshElb.dns_name}"]
}

resource "aws_route53_record" "opsman_alternate" {
  count = "${local.is_alternate ? 1 : 0}"
  provider = "aws.alternate"
  zone_id = "${var.route53_zone_id}"
  name = "opsman"
  type = "A"
  ttl = "900"
  records = ["${aws_eip.opsman.public_ip}"]
}

resource "aws_route53_record" "apps_wild_card_alternate" {
  count = "${local.is_alternate ? 1 : 0}"
  provider = "aws.alternate"
  zone_id = "${var.route53_zone_id}"
  name = "*.${element(split(".", var.apps_domain), 0)}"
  type = "CNAME"
  ttl = "900"
  records = ["${aws_elb.PcfHttpElb.dns_name}"]
}

resource "aws_route53_record" "system_wild_card_alternate" {
  count = "${local.is_alternate ? 1 : 0}"
  provider = "aws.alternate"
  zone_id = "${var.route53_zone_id}"
  name = "*.${element(split(".", var.system_domain), 0)}"
  type = "CNAME"
  ttl = "900"
  records = ["${aws_elb.PcfHttpElb.dns_name}"]
}

resource "aws_route53_record" "ssh_alternate" {
  count = "${local.is_alternate ? 1 : 0}"
  provider = "aws.alternate"
  zone_id = "${var.route53_zone_id}"
  name = "ssh.${element(split(".", var.system_domain), 0)}"
  type = "CNAME"
  ttl = "900"
  records = ["${aws_elb.PcfSshElb.dns_name}"]
}
