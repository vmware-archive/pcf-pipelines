resource "google_compute_instance_group" "ert-http-lb" {
  count       = 3
  name        = "${var.prefix}-http-lb"
  description = "terraform generated pcf instance group that is multi-zone for http/https load balancing"
  zone        = "${element(list(var.gcp_zone_1,var.gcp_zone_2,var.gcp_zone_3), count.index)}"

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_backend_service" "ert_http_lb_backend_service" {
  name        = "${var.prefix}-http-lb-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 30
  enable_cdn  = false

  backend {
    group = "${google_compute_instance_group.ert-http-lb.0.self_link}"
  }

  backend {
    group = "${google_compute_instance_group.ert-http-lb.1.self_link}"
  }

  backend {
    group = "${google_compute_instance_group.ert-http-lb.2.self_link}"
  }

  health_checks = ["${google_compute_http_health_check.cf.self_link}"]
}

resource "google_compute_url_map" "https_lb_url_map" {
  name            = "${var.prefix}-global-pcf"
  default_service = "${google_compute_backend_service.ert_http_lb_backend_service.self_link}"
}

resource "google_compute_target_http_proxy" "http_lb_proxy" {
  name        = "${var.prefix}-http-proxy"
  description = "Load balancing front end http"
  url_map     = "${google_compute_url_map.https_lb_url_map.self_link}"
}

resource "google_compute_target_https_proxy" "https_lb_proxy" {
  name             = "${var.prefix}-https-proxy"
  description      = "Load balancing front end https"
  url_map          = "${google_compute_url_map.https_lb_url_map.self_link}"
  ssl_certificates = ["${google_compute_ssl_certificate.ssl-cert.self_link}"]
}

resource "google_compute_ssl_certificate" "ssl-cert" {
  name_prefix = "${var.prefix}-lb-cert-"
  description = "user provided ssl private key / ssl certificate pair"
  certificate = "${var.pcf_ert_ssl_cert}"
  private_key = "${var.pcf_ert_ssl_key}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_http_health_check" "cf" {
  name = "${var.prefix}-cf-public"

  port                = 8080
  request_path        = "/health"
  check_interval_sec  = 5
  timeout_sec         = 3
  healthy_threshold   = 6
  unhealthy_threshold = 3
}

resource "google_compute_global_forwarding_rule" "cf-http" {
  name       = "${var.prefix}-cf-lb-http"
  ip_address = "${google_compute_global_address.pcf.address}"
  target     = "${google_compute_target_http_proxy.http_lb_proxy.self_link}"
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "cf-https" {
  name       = "${var.prefix}-cf-lb-https"
  ip_address = "${google_compute_global_address.pcf.address}"
  target     = "${google_compute_target_https_proxy.https_lb_proxy.self_link}"
  port_range = "443"
}
