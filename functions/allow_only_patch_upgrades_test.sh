#!/bin/bash
set -u

function TestScriptExitsWithFailureWhenPatchVersionsAreIdentical () (
  # fake the om-linux command
  function om-linux () {
    fakeOmLinux "$*" "${om_linux_fakeresponse_curl_deployedproducts_1_10_1}"
  }

  # fake the cat command
  function cat () {
    echo "${cat_fakeresponse_version_1_10_1}"
  }

  (allow_only_patch_upgrades "a" "b" "c" "acme-product-1" "./")
  exitCode=$?
  return $(Expect $exitCode ToNotBe 0)
)

function TestScriptExitsWithFailureWhenPatchVersionsAreIdenticalOnBOSH () (
  # fake the om-linux command
  function om-linux () {
    fakeOmLinux "$*" "${om_linux_fakeresponse_curl_deployedproducts_1_10_1}"
  }

  # fake the cat command
  function cat () {
    echo "${cat_fakeresponse_version_1_10_3}"
  }

  (allow_only_patch_upgrades "a" "b" "c" "acme-product-2" "./")
  exitCode=$?
  return $(Expect $exitCode ToNotBe 0)
)

function TestAllowOnlyPatchUpgradesShouldAllowAPatchUpgrade () (

  # fake the om-linux command
  function om-linux () {
    fakeOmLinux "$*" "${om_linux_fakeresponse_curl_deployedproducts_1_10_1}"
  }

  # fake the cat command
  function cat () {
    echo "${cat_fakeresponse_version_1_10_2}"
  }
  
  (allow_only_patch_upgrades "a" "b" "c" "acme-product-1" "./")
  exitCode=$?
  return $(Expect $exitCode ToBe 0)
)

function TestAllowOnlyPatchUpgradesShouldFailIfNotAPatchUpgrade () (
  # fake the om-linux command
  function om-linux () {
    fakeOmLinux "$*" "${om_linux_fakeresponse_curl_deployedproducts_1_11_1}"
  }
 
  # fake the cat command
  function cat () {
    echo "${cat_fakeresponse_version_1_10_2}"
  }

  (allow_only_patch_upgrades "a" "b" "c" "acme-product-1" "./")
  exitCode=$?
  return $(Expect $exitCode ToBe 1)
)

function TestAllowOnlyPatchUpgradesShouldFilterOnExactProductName () (

  # fake the om-linux command
  function om-linux () {
    fakeOmLinux "$*" "${om_linux_fakeresponse_curl_deployedproducts_1_10_1}"
  }

  # fake the cat command
  function cat () {
    echo "${cat_fakeresponse_version_1_10_2}"
  }

  (allow_only_patch_upgrades "a" "b" "c" "acme-product" "./")
  exitCode=$?
  return $(Expect $exitCode ToBe 1)
)


############################################################################## 
# fake stuff below 
############################################################################## 

function fakeOmLinux () {
  if [[ "$(echo $1 | grep '/api/v0/deployed/products')" != "" ]]; then 
    echo "$2"

  else 
    echo "fake om-linux does not support this call: $1"
  fi
}

om_linux_fakeresponse_curl_deployedproducts_1_11_1='[
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

om_linux_fakeresponse_curl_deployedproducts_1_10_1='[
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
cat_fakeresponse_version_1_10_2="1.10.2#2017-06-28T03:22:42.162Z"
cat_fakeresponse_version_1_10_1="1.10.1#2017-06-28T03:22:42.162Z"
cat_fakeresponse_version_1_10_3="1.10.3#2017-06-28T03:22:42.162Z"
