#!/bin/bash -eu

function main() {
  echo "Importing ${OPSMAN_SETTINGS_FILENAME} file from OpsMgr"
  curl -vv -k "${OPSMAN_URI}/api/v0/installation_asset_collection" -X POST \
   -F "installation[file]=@./opsmgr-settings/${OPSMAN_SETTINGS_FILENAME}" \
   -F "passphrase=${OPSMAN_PASSWORD}"
   echo "Successfully uploaded opsmgr-settings/${OPSMAN_SETTINGS_FILENAME}. Return code [$?]."
 }

 echo "Running import OpsMgr task..."
 main "${PWD}"
