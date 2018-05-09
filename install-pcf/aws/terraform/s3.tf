resource "aws_s3_bucket" "bosh" {
    bucket = "${var.prefix}-bosh"
    acl = "private"
    force_destroy= true

    tags = "${merge(var.tags, map("Name", format("%s-bosh", var.prefix), "Environment", format("%s", var.prefix)))}"
}

resource "aws_s3_bucket" "buildpacks" {
    bucket = "${var.prefix}-buildpacks"
    acl = "private"
    force_destroy= true

    tags = "${merge(var.tags, map("Name", format("%s-buildpacks", var.prefix), "Environment", format("%s", var.prefix)))}"
}

resource "aws_s3_bucket" "droplets" {
    bucket = "${var.prefix}-droplets"
    acl = "private"
    force_destroy= true

    tags = "${merge(var.tags, map("Name", format("%s-droplets", var.prefix), "Environment", format("%s", var.prefix)))}"
}

resource "aws_s3_bucket" "packages" {
    bucket = "${var.prefix}-packages"
    acl = "private"
    force_destroy= true

    tags = "${merge(var.tags, map("Name", format("%s-packages", var.prefix), "Environment", format("%s", var.prefix)))}"
}

resource "aws_s3_bucket" "resources" {
    bucket = "${var.prefix}-resources"
    acl = "private"
    force_destroy= true

    tags = "${merge(var.tags, map("Name", format("%s-resources", var.prefix), "Environment", format("%s", var.prefix)))}"
}
