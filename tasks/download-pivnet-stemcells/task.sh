#!/bin/bash -eu

function main() {
  local cwd
  cwd="${1}"
  mkdir -p ${cwd}/stemcells

  chmod +x tool-pivnet-cli/pivnet-linux-amd64-0.0.47
  local pivnet="tool-pivnet-cli/pivnet-linux-amd64-0.0.47"

  $pivnet login --api-token=$API_TOKEN
  $pivnet eula --eula-slug=pivotal_software_eula

  for stemcell in $(cat ${cwd}/diagnostic-report/exported-diagnostic-report.json | jq --raw-output '.added_products.deployed[].stemcell' | sort -u); do
    local stemcell_version=$(echo $stemcell | cut -d'-' -f3)
    for product_file_id in $($pivnet pfs -p stemcells -r $stemcell_version --format json | jq .[].id); do
      local product_file_name=$($pivnet product-file -p stemcells -r $stemcell_version -i $product_file_id --format=json | jq .name)
      if [ -n "$(echo "${product_file_name}" | grep -i $IAAS_TYPE)" ]; then
        echo "Downloading stemcell for $product_file_name ..."
        $pivnet download-product-files -p stemcells -r $stemcell_version -i $product_file_id -d ${cwd}/stemcells
      fi
    done
  done
}

main "${PWD}"
