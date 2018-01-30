resource "aws_s3_bucket" "bosh" {
    bucket = "${var.prefix}-bosh"
    acl = "private"
    force_destroy= true

    tags {
        Name = "${var.prefix}-bosh"
        Environment = "${var.prefix}"
    }
}

resource "aws_s3_bucket" "buildpacks" {
    bucket = "${var.prefix}-buildpacks"
    acl = "private"
    force_destroy= true

    tags {
        Name = "${var.prefix}-buildpacks"
        Environment = "${var.prefix}"
    }
}

resource "aws_s3_bucket" "droplets" {
    bucket = "${var.prefix}-droplets"
    acl = "private"
    force_destroy= true

    tags {
        Name = "${var.prefix}-droplets"
        Environment = "${var.prefix}"
    }
}

resource "aws_s3_bucket" "packages" {
    bucket = "${var.prefix}-packages"
    acl = "private"
    force_destroy= true

    tags {
        Name = "${var.prefix}-packages"
        Environment = "${var.prefix}"
    }
}

resource "aws_s3_bucket" "resources" {
    bucket = "${var.prefix}-resources"
    acl = "private"
    force_destroy= true

    tags {
        Name = "${var.prefix}-resources"
        Environment = "${var.prefix}"
    }
}
