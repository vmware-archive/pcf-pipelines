#!/bin/bash -eu

function main() {
   echo "get cf cli"
   wget -O cf-cli.deb "https://cli.run.pivotal.io/stable?release=debian64&source=github"
   dpkg -i cf-cli.deb
   cf --version

   echo "Upgrading buildpacks"
   cf api $PCF_API_URI --skip-ssl-validation
   cf login -u $PCF_USERNAME -p $PCF_PASSWORD -o $PCF_ORG -s $PCF_SPACE
   COUNT=`cf buildpacks | grep --regexp=".zip" --count`
   cf create-buildpack $BUILDPACK_PREFIX-buildpack ./$BUILDPACK_PREFIX-buildpack-latest/*.zip $COUNT+1 --enable
}

echo "Running import OpsMgr task..."
main "${PWD}"
