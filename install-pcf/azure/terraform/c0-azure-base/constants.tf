///////////////////////////////////////////////
//////// Pivotal Customer[0] //////////////////
////////                          /////////////
///////////////////////////////////////////////

// the CPI uses this as a wildcard to stripe disks across multiple storage accounts
data "template_file" "base_storage_account_wildcard" {
  template = "boshvms"
}
