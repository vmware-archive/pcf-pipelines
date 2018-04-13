provider "google" {
  project = "${var.gcp_proj_id}"
  region  = "${var.gcp_region}"
  version = "1.9"
}

provider "random" {
  version = "1.2"
}