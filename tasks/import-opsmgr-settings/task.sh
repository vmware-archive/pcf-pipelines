#!/bin/bash -eu

function main() {
  echo "Importing installation.zip file from OpsMgr"
  curl "${OPSMAN_URI}/api/v0/installation_asset_collection" -X POST \
    -F "installation[file]="./opsmanager-settings \
    -F "passphrase=${OPSMAN_PASSPHRASE}" \
    -k -vv
  echo "Successfully uploaded " ./opsmanager-settings ". Return code [$?]."
}

echo "Running import OpsMgr task..."
main "${PWD}"
