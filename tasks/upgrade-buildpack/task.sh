#!/bin/bash -eu

tar -xvf cf-cli/*.tgz cf
chmod +x cf

echo Using $(cf-cli/cf --version)

./cf api $CF_API_URI --skip-ssl-validation
./cf login -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORG -s $CF_SPACE

COUNT=$(./cf buildpacks | grep --regexp=".zip" --count)
NEW_POSITION=$(expr $COUNT + 1)

echo -n Creating buildpack ${BUILDPACK_NAME}...
./cf create-buildpack $BUILDPACK_NAME buildpack/*.zip $NEW_POSITION --enable
echo done
