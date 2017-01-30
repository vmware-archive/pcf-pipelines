#!/bin/bash -eu

function main() {

RELEASE_NAME=$(cat <<-EOF
"$OPSMAN_RELEASE_NAME"
EOF
)

RELEASE_TAG=$(cat <<-EOF
"$OPSMAN_RELEASE_TAG"
EOF
)

echo $RELEASE_NAME > ./opsman_release_name.txt
echo $RELEASE_TAG > ./opsman_release_tag.txt

mv opsman_release_name.txt ./opsmgr-release-version
mv opsman_release_tag.txt ./opsmgr-release-version

cat ./opsmgr-release-version/opsman_release_name.txt

cat ./opsmgr-release-version/opsman_release_tag.txt
}

main "${PWD}"
