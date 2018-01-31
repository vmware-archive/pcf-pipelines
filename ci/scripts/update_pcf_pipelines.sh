#!/bin/bash

set -eu

function cleanup {
  if [[ -f $tmpfile ]]; then
    rm $tmpfile
  fi
}

trap cleanup EXIT

tmpfile=$(mktemp)

IFS=$'\n'

function write_params() {
  local file=$1
  local prefix=$2
  local key=$3
  local note_path=$4
  local lpass_path="Shared-Customer [0]/${note_path}"
  local contents=$(lpass show $lpass_path  --notes)

  if [[ -z "$contents" ]]; then
    echo Could not fetch contents from $lpass_path
    exit 1
  fi

  cat >> $file <<EOF
$prefix$key: |
EOF

  for line in $contents; do
    echo "  ${prefix}${line}" >> $file
  done
}

write_params $tmpfile "" "install_pcf_aws_current_params" 'lre1-aws/install-pcf-params'
write_params $tmpfile "" "install_pcf_aws_rc_params" 'rc-aws-install/install-pcf-params'
write_params $tmpfile "" "upgrade_ert_aws_current_params" 'lre1-aws/ert-upgrade-params'
write_params $tmpfile "" "upgrade_ops_manager_aws_current_params" 'lre1-aws/upgrade-ops-man-params'
write_params $tmpfile "" "install_pcf_gcp_current_params" 'lre1-gcp/install-pcf-params'
write_params $tmpfile "" "install_pcf_gcp_rc_params" 'rc-gcp-install/install-pcf-params'
write_params $tmpfile "" "upgrade_ert_gcp_current_params" 'lre1-gcp/ert-upgrade-params'
write_params $tmpfile "" "apply_updates_gcp_current_params" 'lre1-gcp/apply-updates-params'
write_params $tmpfile "" "upgrade_ops_manager_gcp_current_params" 'lre1-gcp/opsman-upgrade-params'
write_params $tmpfile "" "install_pcf_azure_current_params" 'lre1-azure/install-pcf-params'
write_params $tmpfile "" "install_pcf_azure_rc_params" 'rc-azure-install/install-pcf-params'
write_params $tmpfile "" "install_pcf_vsphere_slot1_params" 'vsphere-slot1/install-pcf-params'
write_params $tmpfile "" "install_pcf_vsphere_rc_params" 'rc-vsphere-install/install-pcf-params'
write_params $tmpfile "" "upgrade_ert_vsphere_slot1_params" 'vsphere-slot1/upgrade-ert-params'
write_params $tmpfile "" "upgrade_ops_manager_vsphere_slot1_params" 'vsphere-slot1/upgrade-ops-manager-params'
write_params $tmpfile "" "create_offline_pinned_pipelines_params" 'create-offline-pinned-pipelines-params'
write_params $tmpfile "" "unpack_pcf_pipelines_combined_params" 'unpack-pcf-pipelines-combined-params'
write_params $tmpfile "  " "install_pcf_pipeline_params" 'rc-vsphere-offline-install/install-pcf-params'
cat >> $tmpfile <<EOF
  install_pcf_pipeline_name: rc-install-pcf-vsphere-offline
EOF

fly -tci sp -p pcf-pipelines -c ci/pcf-pipelines/pipeline.yml \
  -l $tmpfile \
  -l <(lpass show pcf-pipelines-params --notes) \
  -l <(lpass show pivotal-norm-github --notes) \
  -l <(lpass show czero-pivnet --notes) \
  -l <(lpass show minio-lrpiec03 --notes)
