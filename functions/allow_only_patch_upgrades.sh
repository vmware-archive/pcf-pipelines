#!/bin/bash

set -eu
# 
# Gets major/minor version for deployed product
# and compares them to the product version you are
# trying to install
# if there is any difference (not including patch)
# then we should fail
#
function allow_only_patch_upgrades {
  if [ "$#" -ne 5 ]; then
      echo "Illegal number of arguments."
      echo "usage: allow_only_patch_upgrades <opsman_uri> <opsman_user> <opsman_pass> <product_name> <product_resource_dir>"
  fi
  local OPS_MGR_HOST=$1
  local OPS_MGR_USR=$2
  local OPS_MGR_PWD=$3
  local PRODUCT_NAME=$4
  local PRODUCT_DIR=$5

  local deployed_version=$(
    om-linux \
      --target "https://${OPS_MGR_HOST}" \
      --username "${OPS_MGR_USR}" \
      --password "${OPS_MGR_PWD}" \
      --skip-ssl-validation \
      deployed-products | grep "^| ${PRODUCT_NAME} *|" | awk -F"|" '{print $3 }' | awk -F"." '{print $1"."$2}'
    )
  if [[ `ls ${PRODUCT_DIR} | grep ${deployed_version}` ]]; then
    echo "we have a safe upgrade for version: ${deployed_version}";

  else
    echo "You are trying to install version: "
    ls ${PRODUCT_DIR}
    echo
    echo "Your currently deployed version is: "
    echo "$deployed_version"
    echo
    echo "Pivotal recommends that you only automate
    patch upgrades of PCF, and perform major or minor
    upgrades manually to ensure that no high-impact
    changes to the platform are introduced without
    your prior knowledge."
    echo
    echo "To upgrade patch releases, we suggest using the following version regex in your params file:"
    echo "$deployed_version" | awk -F"." '{print "^"$1"\\\."$2"\\..*$"}'
    exit 1
  fi
}
