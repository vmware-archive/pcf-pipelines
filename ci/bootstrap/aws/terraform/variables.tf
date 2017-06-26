variable "aws_access_key_id" {
  description = "AWS access key with full AWS permissions"
}

variable "aws_secret_access_key" {}

variable "route53_domain" {
  description = "Root domain for new hosted zone, e.g. aws.customer0.net will be used to create a some-name.aws.customer0.net hosted zone"
}

variable "route53_zone_id" {
  description = "ID for Route 53 Hosted Zone that will get a new NS entry for the new hosted zone"
}
