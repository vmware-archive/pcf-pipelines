#!/bin/bash

set -eu

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

cf api $CF_API_URI --skip-ssl-validation
cf auth $CF_USERNAME $CF_PASSWORD

echo Enabling buildpack ${SOURCE_BUILDPACK_NAME}...
cf update-buildpack $SOURCE_BUILDPACK_NAME --enable

set +e
old_buildpack=$(cf buildpacks | grep "${TARGET_BUILDPACK_NAME}\s")
set -e
if [ -n "$old_buildpack" ]; then
  index=$(echo $old_buildpack | cut -d' ' -f2)
  name=$(echo $old_buildpack | cut -d' ' -f1)

  cf delete-buildpack -f $TARGET_BUILDPACK_NAME

  echo Updating buildpack ${SOURCE_BUILDPACK_NAME} index...
  cf update-buildpack $SOURCE_BUILDPACK_NAME -i $index
fi

cf rename-buildpack $SOURCE_BUILDPACK_NAME $TARGET_BUILDPACK_NAME
