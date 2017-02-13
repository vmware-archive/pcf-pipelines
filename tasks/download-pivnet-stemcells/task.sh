#!/bin/bash -eu

function main() {
  local cwd
  cwd="${1}"
  mkdir -p ${cwd}/stemcells

  chmod +x tool-pivnet-cli/pivnet-linux-amd64-0.0.48
  local pivnet="tool-pivnet-cli/pivnet-linux-amd64-0.0.48"

  $pivnet login --api-token=$API_TOKEN
  $pivnet eula --eula-slug=pivotal_software_eula

  for stemcell in $(cat ${cwd}/diagnostic-report/exported-diagnostic-report.json | jq --raw-output '.added_products.deployed[] | select (.name | contains("p-bosh") | not) | .stemcell' | sort -u); do
    local stemcell_version=$(echo $stemcell | cut -d'-' -f3)
    let version=$(echo $stemcell_version | cut -d'.' -f1)
    let patch=$(echo $stemcell_version | cut -d'.' -f2)
    while [[ $($pivnet pfs -p stemcells -r $stemcell_version) == *"release not found"* ]]; do
      let patch=patch-1
      stemcell_version="${version}.${patch}"
    done
    echo "stemcell version: $stemcell_version"
    for product_file_id in $($pivnet pfs -p stemcells -r $stemcell_version --format json | jq .[].id); do
      local product_file_name=$($pivnet product-file -p stemcells -r $stemcell_version -i $product_file_id --format=json | jq .name)
      if [ -n "$(echo "${product_file_name}" | grep -i $IAAS_TYPE)" ]; then
        echo "Downloading stemcell for $product_file_name ..."
        $pivnet download-product-files -p stemcells -r $stemcell_version -i $product_file_id -d ${cwd}/stemcells --accept-eula
      fi
    done
  done
}

main "${PWD}"
