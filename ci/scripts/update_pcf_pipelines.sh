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
  local note_path=$2
  local key=$3

  local lpass_path="Shared-Customer [0]/${note_path}"

  local contents=$(lpass show $lpass_path  --notes)

  if [[ -z "$contents" ]]; then
    echo Could not fetch contents from $lpass_path
    exit 1
  fi

  cat >> $file <<EOF
$key: |
EOF

  for line in $contents; do
    echo "  $line" >> $file
  done
}

write_params $tmpfile "lre1-aws/install-pcf-params" "install_pcf_aws_current_params"
write_params $tmpfile "lre1-aws/ert-upgrade-params" "upgrade_ert_aws_current_params"
write_params $tmpfile "lre1-gcp/install-pcf-params" "install_pcf_gcp_current_params"
write_params $tmpfile "vsphere-slot1/install-pcf-params" "install_pcf_vsphere_slot1_params"

fly -tlrp3 sp -p pcf-pipelines -c ci/pcf-pipelines/pipeline.yml \
  -l $tmpfile \
  -l <(lpass show pcf-pipelines-params --notes) \
  -l <(lpass show czero-github --notes) \
  -l <(lpass show czero-pivnet --notes)
