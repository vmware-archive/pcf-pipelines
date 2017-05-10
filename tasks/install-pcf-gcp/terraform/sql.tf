resource "google_sql_database_instance" "master" {
  region           = "${var.gcp_region}"
  database_version = "MYSQL_5_6"
  name             = "${var.ert_sql_instance_name}"

  settings {
    tier = "db-f1-micro"

    ip_configuration = {
      ipv4_enabled = true

      authorized_networks = [
        {
          name  = "nat-1"
          value = "${google_compute_instance.nat-gateway-pri.network_interface.0.access_config.0.assigned_nat_ip}"
        },
        {
          name  = "nat-2"
          value = "${google_compute_instance.nat-gateway-sec.network_interface.0.access_config.0.assigned_nat_ip}"
        },
        {
          name  = "nat-3"
          value = "${google_compute_instance.nat-gateway-ter.network_interface.0.access_config.0.assigned_nat_ip}"
        },
        {
          name  = "opsman"
          value = "${google_compute_instance.ops-manager.network_interface.0.access_config.0.assigned_nat_ip}"
        },
      ]
    }
  }

  count = "1"
}

resource "google_sql_database" "uaa" {
  name     = "uaa"
  instance = "${google_sql_database_instance.master.name}"

  count = "1"
}

resource "google_sql_database" "ccdb" {
  name       = "ccdb"
  depends_on = ["google_sql_database.uaa"]
  instance   = "${google_sql_database_instance.master.name}"

  count = "1"
}

resource "google_sql_database" "notifications" {
  name       = "notifications"
  depends_on = ["google_sql_database.ccdb"]
  instance   = "${google_sql_database_instance.master.name}"

  count = "1"
}

resource "google_sql_database" "autoscale" {
  name       = "autoscale"
  depends_on = ["google_sql_database.notifications"]
  instance   = "${google_sql_database_instance.master.name}"

  count = "1"
}

resource "google_sql_database" "app_usage_service" {
  name       = "app_usage_service"
  depends_on = ["google_sql_database.autoscale"]
  instance   = "${google_sql_database_instance.master.name}"

  count = "1"
}

resource "google_sql_database" "console" {
  name       = "console"
  depends_on = ["google_sql_database.app_usage_service"]
  instance   = "${google_sql_database_instance.master.name}"

  count = "1"
}

resource "google_sql_database" "routing" {
  name       = "routing"
  depends_on = ["google_sql_database.console"]
  instance   = "${google_sql_database_instance.master.name}"

  count = "1"
}

resource "google_sql_database" "diego" {
  name       = "diego"
  depends_on = ["google_sql_database.routing"]
  instance   = "${google_sql_database_instance.master.name}"

  count = "1"
}

resource "google_sql_user" "ert" {
  name       = "${var.ert_sql_db_username}"
  depends_on = ["google_sql_database.diego"]
  password   = "${var.ert_sql_db_password}"
  instance   = "${google_sql_database_instance.master.name}"
  host       = "%"

  count = "1"
}
