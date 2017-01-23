#!/bin/bash -eu

function main() {
  echo "Targeting OpsMgr instance ${OPSMAN_URI}"
  uaac target "${OPSMAN_URI}/uaa" --skip-ssl-validation
  echo "Getting security token"
  uaac token owner get opsman ${OPSMAN_USERNAME} -s "" -p "${OPSMAN_PASSWORD}"
  export TOKEN="$(uaac context | awk '/^ *access_token\: *([a-zA-Z0-9.\/+\-_]+) *$/ {print $2}' -)"
  echo "Exporting installation.zip file from OpsMgr"
  curl -o "${OPSMAN_SETTINGS_FILENAME}" "${OPSMAN_URI}/api/v0/installation_asset_collection" -X GET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/x-www-form-urlencoded" --insecure -vv --max-time 5400
  echo "Successfully downloaded ${OPSMAN_SETTINGS_FILENAME}. Return code [$?]."
  ls -la
  mv "${OPSMAN_SETTINGS_FILENAME}" ./opsmgr-settings
  echo "${OPSMAN_SETTINGS_FILENAME} moved to opsmgr-settings directory."
}

echo "Running export OpsMgr task..."
main "${PWD}"
