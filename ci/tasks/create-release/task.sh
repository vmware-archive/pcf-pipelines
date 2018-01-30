#!/bin/bash

set -o pipefail
set -eu

chmod +x fly/fly
export PATH="$PWD/fly":$PATH

root=$PWD

pushd pcf-pipelines 1>/dev/null
  ./ci/scripts/inline_functions.sh
popd 1>/dev/null

echo "Creating upgrade-ert pipeline from upgrade-tile pipeline"
pushd pcf-pipelines 1>/dev/null
  mkdir -p upgrade-ert

  sed \
    -e 's/^product_slug:/# product_slug:/' \
    -e 's/^product_name:/# product_name:/' \
    -e 's/\"\*pivotal\"/\"cf\*pivotal\"/' \
    upgrade-tile/params.yml > upgrade-ert/params.yml

  cat ci/yaml_license_header <(
    cat upgrade-tile/pipeline.yml | yaml_patch_linux -o operations/create-upgrade-ert-pipeline.yml
  ) > upgrade-ert/pipeline.yml
popd 1>/dev/null

# Switch pcf-pipelines to point at Pivnet release of pcf-pipelines instead
# of GitHub
version=v$(cat version/version)

set +e # read -d '' requires this
read -r -d '' hardcode_pivnet_version <<EOF
- op: replace
  path: /resources/name=pcf-pipelines-tarball/source/product_version
  value: $version
EOF

read -r -d '' test_for_pcf_pipelines_git <<EOF
- op: test
  path: /resources/name=pcf-pipelines
  value:
    name: pcf-pipelines
    type: git
    source:
      uri: git@github.com:pivotal-cf/pcf-pipelines.git
      branch: master
      private_key: "{{git_private_key}}"
EOF
set -e

files=$(
  find pcf-pipelines \
  -type f \
  -name pipeline.yml |
  grep -v pcf-pipelines/ci
)

for f in ${files[@]}; do
  if [[ $(cat $f | yaml_patch_linux -o <(echo "$test_for_pcf_pipelines_git") 2>/dev/null ) ]]; then
    echo "Using pivnet release for ${f}"
    cat $f |
    yaml_patch_linux \
      -o pcf-pipelines/operations/use-pivnet-release.yml \
      -o <(echo "$hardcode_pivnet_version") \
      > $f.bk
    mv $f.bk $f

    fly format-pipeline --write --config $f

    # Remove git_private_key from params as it is no longer needed
    params_file=$(dirname $f)/params.yml
    sed -i -e '/git_private_key:/d' $params_file
  fi
done

echo "Creating install-pcf/vsphere/offline/pipeline.yml"
mkdir -p pcf-pipelines/install-pcf/vsphere/offline
cat > steamroll_config.yml <<EOF
resource_map:
  "pcf-pipelines": $root/pcf-pipelines
EOF
steamroll -p pcf-pipelines/install-pcf/vsphere/pipeline.yml -c steamroll_config.yml |
yaml_patch_linux \
  -o pcf-pipelines/operations/create-install-pcf-vsphere-offline-pipeline.yml \
  > vsphere-offline.yml
fly format-pipeline -c vsphere-offline.yml > pcf-pipelines/install-pcf/vsphere/offline/pipeline.yml

echo "Creating install-pcf/vsphere/offline/params.yml"
cp pcf-pipelines/install-pcf/vsphere{,/offline}/params.yml
sed -i \
  -e '/pivnet_token:/d' \
  -e '/ert_major_minor_version:/d' \
  -e '/opsman_major_minor_version:/d' \
  -e '/company_proxy_domain:/d' \
  pcf-pipelines/install-pcf/vsphere/offline/params.yml
cat >> pcf-pipelines/install-pcf/vsphere/offline/params.yml <<EOF

# offline resource config
s3_endpoint:
s3_bucket:
s3_access_key_id:
s3_secret_access_key:
EOF

echo "Creating release metadata.yml"
release_date=$(date +%Y-%m-%d)
cat >> pivnet-metadata/metadata.yml <<EOF
---
release:
  version: "${version}"
  release_date: "${release_date}"
  release_notes_url: "https://github.com/pivotal-cf/pcf-pipelines/releases"
  description: |
    Concourse Pipeline Templates and Scripts for PCF Platform Ops Automation
  availability: $AVAILABILITY
  release_type: Beta Release
  eula_slug: "pivotal_beta_eula"
  eccn: "5D002"
  license_exception: "TSU"
  user_group_ids:
  - 6   # Pivotal Internal Early Access
  - 159 # C[0] PCF Automation Pipelines Access
  - 64  #| Pivotal SI Partners Known and Potential Partners.
EOF

exclusions="--exclude .git* --exclude ci --exclude *.go --exclude run_bash_testsuite.sh"
exclusions+=" --exclude pin-pcf-pipelines-git"

echo "Creating release tarball, omitting the following globs:"
echo "${exclusions}"
tar \
  $exclusions \
  --create \
  --gzip \
  --file pcf-pipelines-release-tarball/pcf-pipelines-$version.tgz \
  pcf-pipelines
