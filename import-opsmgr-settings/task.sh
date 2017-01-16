#!/bin/bash -exu

function main() {
  echo "Targeting OpsMgr instance ${OPSMAN_URI}"
  uaac target "${OPSMAN_URI}/uaa" --skip-ssl-validation
  echo "Getting security token"
  uaac token owner get opsman ${OPSMAN_USERNAME} -s "" -p "${OPSMAN_PASSWORD}"
  export TOKEN="$(uaac context | awk '/^ *access_token\: *([a-zA-Z0-9.\/+\-_]+) *$/ {print $2}' -)"
  echo "Importing installation.zip file from OpsMgr"
  curl -o "${OPSMAN_SETTINGS_FILENAME}" "${OPSMAN_URI}/api/v0/installation_asset_collection" -X POST \
    -H "Authorization: Bearer UAA_ACCESS_TOKEN" \
    -F "installation[file]=${OPSMAN_SETTINGS_FILENAME}" \
    -F "passphrase=${OPSMAN_PASSPHRASE}"
  echo "Successfully uploaded ${OPSMAN_SETTINGS_FILENAME}. Return code [$?]."
}

echo "Running import OpsMgr task..."
main()
