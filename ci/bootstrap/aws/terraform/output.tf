output "domain" {
  value = "${aws_route53_zone.pcf-zone.name}"
}

output "s3_bucket" {
  value = "${aws_s3_bucket.terraform.bucket}"
}

output "zone_id" {
  value = "${aws_route53_zone.pcf-zone.zone_id}"
}

output "opsman_certificate" {
  value = "${tls_self_signed_cert.opsman.cert_pem}"
}

output "opsman_certificate_private_key" {
  value = "${tls_private_key.opsman.private_key_pem}"
}

output "opsman_key_pair_name" {
  value = "${aws_key_pair.opsman.key_name}"
}

output "opsman_key_pair_private_key" {
  value = "${tls_private_key.opsman_key_pair.private_key_pem}"
}

output "prefix" {
  value = "${random_pet.server.id}"
}

output "opsman_password" {
  value = "${random_id.opsman_password.id}"
}

output "db_master_password" {
  value = "${random_id.db_master_password.id}"
}

output "db_app_usage_service_password" {
  value = "${random_id.db_app_usage_service_password.id}"
}

output "db_autoscale_password" {
  value = "${random_id.db_autoscale_password.id}"
}

output "db_diego_password" {
  value = "${random_id.db_diego_password.id}"
}

output "db_notifications_password" {
  value = "${random_id.db_notifications_password.id}"
}

output "db_routing_password" {
  value = "${random_id.db_routing_password.id}"
}

output "db_uaa_password" {
  value = "${random_id.db_uaa_password.id}"
}

output "db_ccdb_password" {
  value = "${random_id.db_ccdb_password.id}"
}

output "db_accountdb_password" {
  value = "${random_id.db_accountdb_password.id}"
}

output "db_networkpolicyserverdb_password" {
  value = "${random_id.db_networkpolicyserverdb_password.id}"
}

output "db_nfsvolumedb_password" {
  value = "${random_id.db_nfsvolumedb_password.id}"
}

output "db_locket_password" {
  value = "${random_id.db_locket_password.id}"
}

output "db_silk_password" {
  value = "${random_id.db_silk_password.id}"
}

output "aws_access_key_id" {
  value = "${var.aws_access_key_id}"
}

output "aws_secret_access_key" {
  value = "${var.aws_secret_access_key}"
}
