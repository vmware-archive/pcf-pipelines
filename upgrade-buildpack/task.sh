#!/bin/bash -exu

# function main() {
#   echo "Upgrading buildpacks"
#   cf api $API_URI
#   cf login -u $USERNAME -p $PASSWORD -o $ORGANIZATION -s $SPACE
#   cf update-buildpack -p .
# }
#
# echo "Running import OpsMgr task..."
# main "${PWD}"

cf api $PCF_API_URI --skip-ssl-validation

cf login -u $PCF_USERNAME -p $PCF_PASSWORD -o $PCF_ORG -s $PCF_SPACE

cf apps
