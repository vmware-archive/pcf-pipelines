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

ROOT="${PWD}"

function main() {
  for yaml_filename in ${ROOT}/yaml/${GLOBS}; do
    local json_filename="${ROOT}/json/$(basename ${yaml_filename} .yml)"
    yaml2json "${yaml_filename}" > "${json_filename}.json"
  done
}

function yaml2json() {
  local file="${1}"
  ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < "${file}"
}

main
