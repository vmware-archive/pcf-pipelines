terraform {
  required_version = "> 0.10"
}

provider "aws" {
  version = "> 1.0.0"
  region  = "${var.aws_region}"
}
