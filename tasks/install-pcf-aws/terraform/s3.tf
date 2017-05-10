resource "aws_s3_bucket" "pcf-bosh" {
    bucket = "${var.environment}-pcf-bosh"
    acl = "private"
    force_destroy= true

    tags {
        Name = "${var.environment}-pcf-bosh"
        Environment = "${var.environment}"
    }
}

resource "aws_s3_bucket" "pcf-buildpacks" {
    bucket = "${var.environment}-pcf-buildpacks"
    acl = "private"
    force_destroy= true

    tags {
        Name = "${var.environment}-pcf-buildpacks"
        Environment = "${var.environment}"
    }
}

resource "aws_s3_bucket" "pcf-droplets" {
    bucket = "${var.environment}-pcf-droplets"
    acl = "private"
    force_destroy= true

    tags {
        Name = "${var.environment}-pcf-droplets"
        Environment = "${var.environment}"
    }
}

resource "aws_s3_bucket" "pcf-packages" {
    bucket = "${var.environment}-pcf-packages"
    acl = "private"
    force_destroy= true

    tags {
        Name = "${var.environment}-pcf-packages"
        Environment = "${var.environment}"
    }
}

resource "aws_s3_bucket" "pcf-resources" {
    bucket = "${var.environment}-pcf-resources"
    acl = "private"
    force_destroy= true

    tags {
        Name = "${var.environment}-pcf-resources"
        Environment = "${var.environment}"
    }
}
