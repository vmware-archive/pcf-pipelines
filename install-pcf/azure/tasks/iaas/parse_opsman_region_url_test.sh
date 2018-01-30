#!/bin/bash
set -u

function TestValidRegionAndYamlFileYieldsURL () (
  local yaml_file_path=$(mktemp)
  local east_us_url="https://opsmanagereastus.blob.core.windows.net/images/ops-manager-1.11.5.vhd"
  echo "---
west_us: https://opsmanagerwestus.blob.core.windows.net/images/ops-manager-1.11.5.vhd
east_us: ${east_us_url}
west_europe: https://opsmanagerwesteurope.blob.core.windows.net/images/ops-manager-1.11.5.vhd
southeast_asia: https://opsmanagersoutheastasia.blob.core.windows.net/images/ops-manager-1.11.5.vhd
" > ${yaml_file_path}
  local vhd_url=$(parseRegionURL "east_us" "${yaml_file_path}")
  rm $yaml_file_path
  echo ${vhd_url}
  echo ${east_us_url}
  return $(Expect "${vhd_url}" ToBe "${east_us_url}")
)


