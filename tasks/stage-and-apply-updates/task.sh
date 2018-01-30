#!/bin/bash

set -eu

function om() {
  om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --client-id "${OPSMAN_CLIENT_ID}" \
    --client-secret "${OPSMAN_CLIENT_SECRET}" \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    $@
}

function stage_product() {
  om stage-product --product-name $1 --product-version $2
}

function main() {
  local available_products=$(om curl -path "/api/v0/available_products")
  local staged_products=$(om curl -path "/api/v0/staged/products")
  local products=$(echo ${staged_products} | jq -r ' .[] | .type' | grep -v "p-bosh")

  for product_name in ${products}; do
    echo "Checking ${product_name}..."

    local available_version="$(echo ${available_products} | jq -r --arg product_name ${product_name} '.[] | select(.name == $product_name) | .product_version' | sort | tail -1)"
    local staged_version="$(echo ${staged_products} | jq -r --arg product_name ${product_name} '.[] | select(.type == $product_name) | .product_version')"
    echo "Available Version: ${available_version}"
    echo "Staged Version: ${staged_version}"

    if [[ $(semver-linux compare "${available_version}" "${staged_version}") > 0 ]]; then
      stage_product "${product_name}" "${available_version}"
    else
      echo "Nothing to do for ${product_name}"
    fi
    echo ""
  done
  om apply-changes --ignore-warnings
}

main
