#!/bin/bash -e

function fn_ert_balanced_azs {
  local azs_csv=$1
  echo $azs_csv | jq -c  -R 'split(",") | map({name: .})'
}