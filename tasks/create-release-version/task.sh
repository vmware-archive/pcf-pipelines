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

function main() {

RELEASE_NAME=$(cat <<-EOF
$OPSMAN_RELEASE_NAME
EOF
)

RELEASE_TAG=$(cat <<-EOF
$OPSMAN_RELEASE_TAG
EOF
)

echo $RELEASE_NAME > ./opsman_release_name.txt
echo $RELEASE_TAG > ./opsman_release_tag.txt

mv opsman_release_name.txt ./opsmgr-release-version
mv opsman_release_tag.txt ./opsmgr-release-version

cat ./opsmgr-release-version/opsman_release_name.txt

cat ./opsmgr-release-version/opsman_release_tag.txt
}

main "${PWD}"
