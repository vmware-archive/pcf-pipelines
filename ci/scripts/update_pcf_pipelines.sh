#!/bin/bash

set -eu

function cleanup {
  if [[ -f $tmpfile ]]; then
    rm $tmpfile
  fi
}

trap cleanup EXIT

install_pcf_aws_current_params=$(lpass show Shared-Customer\ [0]/lre1-aws/install-pcf-params --notes)
upgrade_ert_aws_current_params=$(lpass show Shared-Customer\ [0]/lre1-aws/ert-upgrade-params --notes)

tmpfile=$(mktemp)

IFS=$'\n'

cat > $tmpfile <<EOF
install_pcf_aws_current_params: |
EOF

for line in $install_pcf_aws_current_params; do
  echo "  $line" >> $tmpfile
done

cat >> $tmpfile <<EOF
upgrade_ert_aws_current_params: |
EOF

for line in $upgrade_ert_aws_current_params; do
  echo "  $line" >> $tmpfile
done

fly -tc02 sp -p pcf-pipelines -c ci/pcf-pipelines/pipeline.yml -l $tmpfile -l <(lpass show pcf-pipelines-params --notes)
