#!/bin/bash

set -eu

apply_yaml_patch() {
  sourceYaml="${1}"
  operationFile="${2}"
  outputYaml="${3}"

  cat $sourceYaml | yaml_patch_linux -o ./updatedOperationFile.yml > $outputYaml
}

patch_install_pcf() {
  iaas="${1}"
  resourceName="${2}"
  lastJobName="${3}"
  lockResourceName="${4}"
  lockName="${5}"

  sourceYaml="unpatched-release/pcf-pipelines/install-pcf/$iaas/pipeline.yml"
  operationFile="pcf-pipelines/ci/operations/add-release-lock-to-install-pcf.yml"
  outputYaml="patched-release/pcf-pipelines/install-pcf/$iaas/pipeline.yml"

  sed "s/LOCK_RESOURCE_NAME/${lockResourceName}/g" $operationFile > ./updatedOperationFile.yml
  sed -i "s/LOCK_NAME/${lockName}/g" ./updatedOperationFile.yml
  sed -i "s/LOCK_POOL_NAME/${iaas}/g" ./updatedOperationFile.yml
  sed -i "s/RESOURCE_NAME/${resourceName}/g" ./updatedOperationFile.yml
  sed -i "s/LAST_JOB_NAME/${lastJobName}/g" ./updatedOperationFile.yml

  apply_yaml_patch $sourceYaml ./updatedOperationFile.yml $outputYaml

  # required transforms specific to iaas
  if [ "$iaas" == "azure" ]; then

    cat > ./add-job-to-group.yml <<EOF
- op: add
  path: /groups/name=all/jobs/-
  value: release-lock
EOF

    cp $outputYaml ./copyOfOutput.yml
    cat ./copyOfOutput.yml | yaml_patch_linux -o ./add-job-to-group.yml > $outputYaml
  fi
}

pushd patched-release > /dev/null
  cp -r ../unpatched-release/* .
popd > /dev/null

# install-pcf-vsphere
patch_install_pcf vsphere pcf-ops-manager deploy-ert vsphere-lock install-pcf

# install-pcf-gcp
patch_install_pcf gcp pivnet-opsmgr deploy-ert gcp-lock install-pcf

# install-pcf-azure
patch_install_pcf azure pivnet-opsmgr deploy-ert azure-lock install-pcf

# install-pcf-aws
patch_install_pcf aws terraform-state deploy-ert aws-lock install-pcf
