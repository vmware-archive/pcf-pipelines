#!/bin/bash

set -eu

function main() {
  local configuration_properties="$(cat ${PRODUCT_PROPERTIES_FILE})"
  local configuration_network="$(cat ${PRODUCT_NETWORK_FILE})"
  local configuration_resources="$(cat ${PRODUCT_RESOURCES_FILE})"

  om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    --skip-ssl-validation \
    configure-product \
    --product-name "${PRODUCT_NAME}" \
    --product-properties "${configuration_properties}" \
    --product-network "${configuration_network}" \
    --product-resources "${configuration_resources}"
}

main
