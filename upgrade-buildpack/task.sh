#!/bin/bash -eu

function main() {
  echo "get cf cli"
  wget -O cf-cli.deb "https://cli.run.pivotal.io/stable?release=debian64&source=github"
  dpkg -i cf-cli.deb
  cf --version

  # Convert buildpack prefix to buildpack notation
  if [ $BUILDPACK_PREFIX == "NET" ]; then
    BUILDPACK_PREFIX="dotnet_core"
  elif [ $BUILDPACK_PREFIX == "tc" ]; then
    BUILDPACK_PREFIX="tc_server"
  fi

  echo "Upgrading buildpacks"
  cf api $PCF_API_URI --skip-ssl-validation
  cf login -u $PCF_USERNAME -p $PCF_PASSWORD -o $PCF_ORG -s $PCF_SPACE
  COUNT=`cf buildpacks | grep --regexp=".zip" --count`
  NEW_POSITION=`expr $COUNT + 1`
  cf create-buildpack $BUILDPACK_PREFIX-buildpack ./$BUILDPACK_PREFIX-buildpack-latest/*.zip $NEW_POSITION --enable
}

echo "Running import OpsMgr task..."
main "${PWD}"
