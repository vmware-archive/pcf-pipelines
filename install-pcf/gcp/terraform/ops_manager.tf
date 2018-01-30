resource "google_compute_instance" "ops-manager" {
  name         = "${var.prefix}-ops-manager"
  depends_on   = ["google_compute_subnetwork.subnet-ops-manager"]
  machine_type = "n1-standard-2"
  zone         = "${var.gcp_zone_1}"

  tags = ["${var.prefix}-opsman", "allow-https"]

  boot_disk {
    initialize_params {
      image = "${var.pcf_opsman_image_name}"
      size  = 50
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-ops-manager.name}"

    access_config {
      nat_ip = "${google_compute_address.opsman.address}"
    }
  }
}

resource "google_storage_bucket" "director" {
  name          = "${var.prefix}-director"
  location      = "${var.gcp_storage_bucket_location}"
  force_destroy = true
}
