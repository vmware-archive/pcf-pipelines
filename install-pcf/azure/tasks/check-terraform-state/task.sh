#!/bin/bash

set -e

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

function getBlobFiles ()
{
  if az storage blob list --account-name ${TERRAFORM_AZURE_STORAGE_ACCOUNT_NAME} --account-key ${TERRAFORM_AZURE_STORAGE_ACCESS_KEY} -c ${TERRAFORM_AZURE_STORAGE_CONTAINER_NAME}; then
    blobs=$(az storage blob list --account-name ${TERRAFORM_AZURE_STORAGE_ACCOUNT_NAME} --account-key ${TERRAFORM_AZURE_STORAGE_ACCESS_KEY} -c ${TERRAFORM_AZURE_STORAGE_CONTAINER_NAME})
    files=$(echo "$blobs" | jq -r .[].name)
  else
    echo "az command to failed to successfully complete, check for proper variable values."
    exit 1
  fi
}

function checkFileExists()
{
  set +e
  echo ${files} | grep ${TERRAFORM_AZURE_STATEFILE_NAME}
  if [ "$?" -gt "0" ]; then
    echo "Desired ${TERRAFORM_AZURE_STATEFILE_NAME} state file not found. Proper access to storage is available to initialize in the create-infrastructure task."
    return 0
  else
    echo "Existing ${TERRAFORM_AZURE_STATEFILE_NAME} file found. Remove the file from blob storage or change the terraform_azure_statefile_name for this task to pass. Proceed to wipe-env or create-infrastructure tasks if this is expected."
    return 1
  fi
}

getBlobFiles
checkFileExists
