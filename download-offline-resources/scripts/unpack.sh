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

if [[ $# != 2 ]]; then
  echo "usage: $0 <target> <dest>"
  exit 1
fi

unpack $1 $2
