#!/bin/bash
set -u

om_linux_fakeresponse_deployproducts_1_13="+----------------+------------------+
  |      NAME      |     VERSION      |
  +----------------+------------------+
  | acme-product-1 | 1.13.0-build.100 |
  | acme-product-2 | 1.8.0            |
  +----------------+------------------+
  "
om_linux_fakeresponse_deployproducts_1_11="+----------------+------------------+
  |      NAME      |     VERSION      |
  +----------------+------------------+
  | acme-product-1 | 1.11.0-build.100 |
  | acme-product-2 | 1.8.0            |
  +----------------+------------------+
  "
ls_fakeresponse_deployproducts_1_13="blah-1.13.yml manifest.yml blah.html"

function TestAllowOnlyPatchUpgradesShouldAllowAPatchUpgrade () (

  # fake the om-linux command
  function om-linux () {
    callset="$@"
    if (echo ${callset} | grep "deployed-products"); then 
      echo "${om_linux_fakeresponse_deployproducts_1_13}"
    else 
      echo "unsupported call to fake om-linux ${callset}"
    fi
  }

  # fake the ls command
  function ls () {
    echo "${ls_fakeresponse_deployproducts_1_13}"
  }
  
  (allow_only_patch_upgrades "a" "b" "c" "acme-product-1" "./")
  exitCode=$?
  return $(Expect $exitCode ToBe 0)
)

function TestAllowOnlyPatchUpgradesShouldFailIfNotAPatchUpgrade () (
  # fake the om-linux command
  function om-linux () {
    callset="$@"
    if (echo ${callset} | grep "deployed-products"); then 
      echo "${om_linux_fakeresponse_deployproducts_1_11}"
    else 
      echo "unsupported call to fake om-linux ${callset}"
    fi
  }
 
  # fake the ls command
  function ls () {
    echo "${ls_fakeresponse_deployproducts_1_13}"
  }
  (allow_only_patch_upgrades "a" "b" "c" "acme-product-1" "./")
  exitCode=$?
  return $(Expect $exitCode ToBe 1)
)

function TestAllowOnlyPatchUpgradesShouldFilterOnExactProductName () (

  # fake the om-linux command
  function om-linux () {
    callset="$@"
    if (echo ${callset} | grep "deployed-products"); then 
      echo "${om_linux_fakeresponse_deployproducts_1_13}"
    else 
      echo "unsupported call to fake om-linux ${callset}"
    fi
  }

  # fake the ls command
  function ls () {
    echo "${ls_fakeresponse_deployproducts_1_13}"
  }

  (allow_only_patch_upgrades "a" "b" "c" "acme-product" "./")
  exitCode=$?
  return $(Expect $exitCode ToBe 1)
)
