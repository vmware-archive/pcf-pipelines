#!/bin/bash -eu

# Copyright 2017-Present Pivotal Software, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

tar -xvf cf-cli/*.tgz cf
chmod +x cf

echo Using $(cf-cli/cf --version)

./cf api $CF_API_URI --skip-ssl-validation
./cf auth $CF_USERNAME $CF_PASSWORD

COUNT=$(./cf buildpacks | grep --regexp=".zip" --count)
NEW_POSITION=$(expr $COUNT + 1)

echo -n Creating buildpack ${BUILDPACK_NAME}...
./cf create-buildpack $BUILDPACK_NAME buildpack/*.zip $NEW_POSITION --enable
echo done
