resource "random_id" "opsman_password" {
  byte_length = 16
}

resource "random_id" "db_master_password" {
  byte_length = 16
}

resource "random_id" "db_app_usage_service_password" {
  byte_length = 16
}

resource "random_id" "db_autoscale_password" {
  byte_length = 16
}

resource "random_id" "db_diego_password" {
  byte_length = 16
}

resource "random_id" "db_notifications_password" {
  byte_length = 16
}

resource "random_id" "db_routing_password" {
  byte_length = 16
}

resource "random_id" "db_uaa_password" {
  byte_length = 16
}

resource "random_id" "db_ccdb_password" {
  byte_length = 16
}

resource "random_id" "db_accountdb_password" {
  byte_length = 16
}

resource "random_id" "db_networkpolicyserverdb_password" {
  byte_length = 16
}

resource "random_id" "db_nfsvolumedb_password" {
  byte_length = 16
}

resource "random_id" "db_silk_password" {
  byte_length = 16
}

resource "random_id" "db_locket_password" {
  byte_length = 16
}
