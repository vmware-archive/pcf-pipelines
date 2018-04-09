provider "google" {
  project = "${var.gcp_proj_id}"
  region  = "${var.gcp_region}"
  version = "1.8"
}

provider "random" {
  version = "1.2"
}