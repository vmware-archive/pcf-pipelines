resource "google_storage_bucket" "buildpacks" {
  name          = "${var.prefix}-buildpacks"
  location      = "${var.gcp_storage_bucket_location}"
  force_destroy = true
}

resource "google_storage_bucket" "droplets" {
  name          = "${var.prefix}-droplets"
  location      = "${var.gcp_storage_bucket_location}"
  force_destroy = true
}

resource "google_storage_bucket" "packages" {
  name          = "${var.prefix}-packages"
  location      = "${var.gcp_storage_bucket_location}"
  force_destroy = true
}

resource "google_storage_bucket" "resources" {
  name          = "${var.prefix}-resources"
  location      = "${var.gcp_storage_bucket_location}"
  force_destroy = true
}
