#!/bin/bash
set -u

function TestAllowOnlyPatchUpgradesShouldAllowAPatchUpgrade () (

  # fake the om-linux command
  function om-linux () {
    fakeOmLinux "$*" "${om_linux_fakeresponse_curl_deployedproducts_1_10}"
  }

  # fake the ls command
  function ls () {
    echo "${ls_fakeresponse_deployproducts_1_10}"
  }
  
  (allow_only_patch_upgrades "a" "b" "c" "acme-product-1" "./")
  exitCode=$?
  return $(Expect $exitCode ToBe 0)
)

function TestAllowOnlyPatchUpgradesShouldFailIfNotAPatchUpgrade () (
  # fake the om-linux command
  function om-linux () {
    fakeOmLinux "$*" "${om_linux_fakeresponse_curl_deployedproducts_1_11}"
  }
 
  # fake the ls command
  function ls () {
    echo "${ls_fakeresponse_deployproducts_1_10}"
  }
  (allow_only_patch_upgrades "a" "b" "c" "acme-product-1" "./")
  exitCode=$?
  return $(Expect $exitCode ToBe 1)
)

function TestAllowOnlyPatchUpgradesShouldFilterOnExactProductName () (

  # fake the om-linux command
  function om-linux () {
    fakeOmLinux "$*" "${om_linux_fakeresponse_curl_deployedproducts_1_10}"
  }

  # fake the ls command
  function ls () {
    echo "${ls_fakeresponse_deployproducts_1_10}"
  }

  (allow_only_patch_upgrades "a" "b" "c" "acme-product" "./")
  exitCode=$?
  return $(Expect $exitCode ToBe 1)
)



















function fakeOmLinux () {
  if [[ "$(echo $1 | grep '/api/v0/deployed/products')" != "" ]]; then 
    echo "$2"

  else 
    echo "fake om-linux does not support this call: $1"
  fi
}

om_linux_fakeresponse_curl_deployedproducts_1_11='[
   {
      "installation_name":"p-bosh",
      "guid":"p-bosh-9c60538f074d2fcad102",
      "type":"acme-product-2",
      "product_version":"1.11.3.0"
   },
   {
      "installation_name":"cf-c35302beebdb56a73f85",
      "guid":"cf-c35302beebdb56a73f85",
      "type":"acme-product-1",
      "product_version":"1.11.1"
   }
]'

om_linux_fakeresponse_curl_deployedproducts_1_10='[
   {
      "installation_name":"p-bosh",
      "guid":"p-bosh-9c60538f074d2fcad102",
      "type":"acme-product-2",
      "product_version":"1.10.3.0"
   },
   {
      "installation_name":"cf-c35302beebdb56a73f85",
      "guid":"cf-c35302beebdb56a73f85",
      "type":"acme-product-1",
      "product_version":"1.10.1"
   }
]'

ls_fakeresponse_deployproducts_1_10="blah-1.10.yml manifest.yml blah.html"
