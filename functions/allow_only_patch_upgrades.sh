#!/bin/bash

set -eu
# 
# Gets all major/minor versions for deployed products
# and compares them to all major/minor versions
# that are currently staged in ops manager
# if there is any difference (not including patch)
# then we should fail
#
function allow_only_patch_upgrades {
  if [ "$#" -ne 3 ]; then
      echo "Illegal number of arguments."
      echo "usage: allow_only_patch_upgrades <opsman_uri> <opsman_user> <opsman_pass>"
  fi
  local OPS_MGR_HOST=$1
  local OPS_MGR_USR=$2
  local OPS_MGR_PWD=$3
  local staged_versions=$(
    om-linux \
      --target "https://${OPS_MGR_HOST}" \
      --username "${OPS_MGR_USR}" \
      --password "${OPS_MGR_PWD}" \
      --skip-ssl-validation \
      staged-products | awk -F"|" '{print $3 }' | awk -F"." '{print $1"."$2}' | egrep -v "VERSION|^\." | uniq | sort
    )

  local deployed_versions=$(
    om-linux \
      --target "https://${OPS_MGR_HOST}" \
      --username "${OPS_MGR_USR}" \
      --password "${OPS_MGR_PWD}" \
      --skip-ssl-validation \
      deployed-products | awk -F"|" '{print $3 }' | awk -F"." '{print $1"."$2}' | egrep -v "VERSION|^\." | uniq | sort
    )

  if [[ $staged_versions != $deployed_versions ]]; then 
    echo "Staged versions: "
    echo "$staged_versions"
    echo "Deployed versions: "
    echo "$deployed_versions"
    echo "Pivotal recommends that you only automate
    patch upgrades of PCF, and perform major or minor
    upgrades manually to ensure that no high-impact
    changes to the platform are introduced without
    your prior knowledge."
    exit 1
  fi
}
