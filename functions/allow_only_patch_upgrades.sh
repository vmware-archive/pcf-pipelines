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
  local version="$(get_deployed_product_version ${OPS_MGR_HOST} ${OPS_MGR_USR} ${OPS_MGR_PWD} ${PRODUCT_NAME})"
  local deployed_version=${version// }
  local new_version="$(get_new_product_version $PRODUCT_DIR)"

  if [[ ${deployed_version// } == "" ]];then
      echo "version check yielded empty version information from product call:"
      echo $deployed_version
      exit 1 
  fi

  if [[ ${new_version} == ${deployed_version} ]]; then
    echo "we have a safe upgrade for version: ${deployed_version}";

  else
    echo "You are trying to install version: "
    cat ${PRODUCT_DIR}/version
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

function get_new_product_version () {
  local PRODUCT_DIR=$1
  local complete_new_version=$(cat ${PRODUCT_DIR}/version)
  local new_version=$(format_semver_major_minor ${complete_new_version})
  echo ${new_version// }
}

function format_semver_major_minor () {
  echo $1 | awk -F"." '{print $1"."$2}'
}

function get_deployed_product_version () {
  local OPS_MGR_HOST=$1
  local OPS_MGR_USR=$2
  local OPS_MGR_PWD=$3
  local PRODUCT_NAME=$4
  local products="$( om-linux \
    --target "https://${OPS_MGR_HOST}" \
    --username "${OPS_MGR_USR}" \
    --password "${OPS_MGR_PWD}" \
    --skip-ssl-validation \
    curl --path /api/v0/deployed/products -s )"
  local complete_version=$(echo "${products}" | jq --arg product "$PRODUCT_NAME" '.[] | select(.type == $product) | .product_version')
  local major_minor_version=""
  if [[ "${complete_version// }" != "" ]]; then
    local major_minor_version=$(format_semver_major_minor "${complete_version//\"}")
  fi
  echo "${major_minor_version}"
}
