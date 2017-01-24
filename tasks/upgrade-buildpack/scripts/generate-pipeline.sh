#!/bin/bash

if [ "$#" -eq 0 ]; then
  echo -e "Usage: generate-pipeline [product ...]\n" \
          "available products: Binary, .NET, Go, Java, NodeJS, PHP, Python, Ruby, Staticfile, tc"
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
resources:\n\
- name: task-bundle-release\n\
  type: github-release\n\
  source:\n\
    user: c0-ops\n\
    repository: concourse-tasks-bundle\n\
    access_token: {{github_token}}\n\
    pre_release: true"
for param in "$@"; do
  echo -e \
"- name: ${param}-buildpack-latest\n\
  type: pivnet\n\
  check_every: {{poll_interval}}\n\
  source:\n\
    api_token: {{pcf_pivnet_token}}\n\
    product_slug: buildpacks\n\
    product_version: ${param}*"
done

echo -e \
"\njobs:\n\
- name: download-buildpacks\n\
  plan:\n\
  - aggregate:\n\
    - get: task-bundle-release\n\
      version: { tag: 'v0.0.11' }" #todo remove specific tag
for param in "$@"; do
  echo -e "  - get: ${param}-buildpack-latest"
  if [ "${param}" == "Java" ]; then
    echo -e \
"    params:\n\
      globs:\n\
      - \"*offline*\""
  fi
done

echo -e \
"  - task: unpack-tasks\n\
    config:\n\
      platform: linux\n\
      image_resource:\n\
        type: docker-image\n\
        source:\n\
          repository: cloudfoundry/cflinuxfs2\n\
      inputs:\n\
      - name: task-bundle-release\n\
      outputs:\n\
      - name: concourse-tasks-bundle\n\
      run:\n\
        path: sh\n\
        args:\n\
        - -exc\n\
        - |\n\
         tar xvzf task-bundle-release/tasks-bundle.tgz -C concourse-tasks-bundle"
for param in "$@"; do
echo -e \
"  - task: update-${param}-buildpack\n\
    config:\n\
      platform: linux\n\
      image_resource:\n\
        type: docker-image\n\
        source:\n\
          repository: cloudfoundry/cflinuxfs2\n\
      inputs:\n\
      - name: ${param}-buildpack-latest\n\
      - name: concourse-tasks-bundle\n\
      params:\n\
        PCF_API_URI: {{pcf_api_uri}}\n\
        PCF_ORG: {{pcf_org}}\n\
        PCF_USERNAME: {{pcf_username}}\n\
        PCF_PASSWORD: {{pcf_password}}\n\
        PCF_SPACE: {{pcf_space}}
        BUILDPACK_PREFIX: ${param}\n\
      run:\n\
        path: ./concourse-tasks-bundle/upgrade-buildpack/task.sh"
done
