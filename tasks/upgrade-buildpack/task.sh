#!/bin/bash -eu

tar -xvf cf-cli/*.tgz cf
chmod +x cf

echo Using $(cf-cli/cf --version)

./cf api $PCF_API_URI --skip-ssl-validation
./cf login -u $PCF_USERNAME -p $PCF_PASSWORD -o $PCF_ORG -s $PCF_SPACE

COUNT=$(./cf buildpacks | grep --regexp=".zip" --count)
NEW_POSITION=$(expr $COUNT + 1)

echo -n Creating buildpack ${BUILDPACK_NAME}...
./cf create-buildpack $BUILDPACK_NAME buildpack/*.zip $NEW_POSITION --enable
echo done
