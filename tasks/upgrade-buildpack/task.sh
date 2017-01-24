#!/bin/bash -eu

function main() {
  tar -xvf cf-cli/*.tgz cf
  chmod +x cf

  echo Using $(cf-cli/cf --version)
  cf api $PCF_API_URI --skip-ssl-validation
  cf login -u $PCF_USERNAME -p $PCF_PASSWORD -o $PCF_ORG -s $PCF_SPACE
  echo -n Creating buildpack ${BUILDPACK_NAME}...
  cf create-buildpack $BUILDPACK_NAME buildpack/*.zip 11 --enable
  echo done
}

main "${PWD}"
