resource "google_storage_bucket" "buildpacks" {
  name          = "${var.prefix}-buildpacks"
  force_destroy = true
}

resource "google_storage_bucket" "droplets" {
  name          = "${var.prefix}-droplets"
  force_destroy = true
}

resource "google_storage_bucket" "packages" {
  name          = "${var.prefix}-packages"
  force_destroy = true
}

resource "google_storage_bucket" "resources" {
  name          = "${var.prefix}-resources"
  force_destroy = true
}
