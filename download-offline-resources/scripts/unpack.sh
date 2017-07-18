#!/bin/bash

function unpack () {
  local target_dir=$1
  local destination_dir=$2
  ls ${target_dir}/*.tgz | 
    xargs basename -a |
    sed s/\.tgz//g | 
    awk \
      -v target_dir=${target_dir} \
      -v dest_dir=${destination_dir} \
      '{system("echo unpacking: "$1"; mkdir -p "dest_dir"/"$1"; tar -xvzf "target_dir"/"$1".tgz -C "dest_dir"/"$1)}'
}

function store () {
  local endpoint=$1
  local source_dir=$2
  local bucket_name=$3
  local remote_folder_name=$4
  aws --endpoint-url=${endpoint} s3 cp ${source_dir} s3://${bucket_name}/${remote_folder_name} --recursive --debug
}

if [[ $# != 4 ]]; then
  echo "usage: $0 <tarball-dir-target> <unpack-dest> <s3-endpoint> <bucket-name>"
  exit 1
fi
tarball_target=$1
unpack_dest=$2
s3_endpoint=$3
bucket_name=$4
remote_folder_name=$(basename ${unpack_dest})
unpack ${tarball_target} ${unpack_dest}
store ${s3_endpoint} ${unpack_dest} ${bucket_name} ${remote_folder_name}
