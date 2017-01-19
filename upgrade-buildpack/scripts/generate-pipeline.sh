#!/bin/bash

if [ "$#" -eq 0 ]; then
  echo -e "Usage: generate-pipeline [product ...]\n" \
          "available products: binary, dotnetcore, go, java, nodejs, php, python, ruby, staticfile, tcserver"
  exit 1
fi

echo -e \
"resource_types:\n\
- name: pivnet\n\
  type: docker-image\n\
  source:\n\
    repository: pivotalcf/pivnet-resource\n\
    tag: latest-final\n\
\
resources:"
echo -e \
"- name: cfcli\n\
  type: cf\n\
  source:\n\
    api: {{pcf_api_uri}}\n\
    username: {{pcf_username}}\n\
    password: {{pcf_password}}\n\
    organization: {{pcf_org}}\n\
    space: {{pcf_space}}"

for param in "$@"; do
  echo -e \
"- name: ${param}-buildpack-latest\n\
  type: pivnet\n\
  check_every: {{pcf_pivnet_poll_interval}}\n\
  source:\n\
    api_token: {{pcf_pivnet_token}}\n\
    product_slug: buildpacks\n\
    product_version: ${param}*"
done

echo -e \
"\njobs:\n\
- name: download-buildbacks\n\
  plan:\n\
  - aggregate:"

for param in "$@"; do
  echo -e "  - get: ${param}-buildpack-latest"
  if [ "${param}" == "java" ]; then
    echo -e \
"    params:\n\
      globs:\n\
      - \"*offline*\""
  fi
done
echo -e \
"- task: upload-to-ert\n\
  config:\n\
    platform: linux\n\
    image_resource:\n\
      type: docker-image\n\
      source:\n\
        repository: cloudfoundry/cflinuxfs2\n\
    inputs:"
    for param in "$@"; do
      echo -e "    - name: ${param}-buildpack-latest"
    done
  echo -e \
"  run:\n\
    path: ./update-to-ert.sh\n\
    - put: cfcli"
