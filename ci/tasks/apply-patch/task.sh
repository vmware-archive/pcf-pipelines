#!/bin/bash

set -eu

function main() {
  local temp_pipeline_file=$(mktemp)
  local yaml_patch_args=$(
    echo "${PATCH_FILES}" | \
      xargs -n 1 echo "-o")

  echo "Applying the following patch files to ${PIPELINE_FILE}:"
  echo "${PATCH_FILES}"

  cat "${PIPELINE_FILE}" | \
    yaml_patch_linux ${yaml_patch_args} \
    > "${temp_pipeline_file}"

  cat "${temp_pipeline_file}" \
    > "${PIPELINE_FILE}"

  rm -rf patched-release/*
  cp -R unpatched-release/* patched-release
}

main
