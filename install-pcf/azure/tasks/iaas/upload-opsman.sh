#!/bin/bash
set -ue

current_dir=$( dirname "${BASH_SOURCE[0]}" )
source "${current_dir}/parse_opsman_region_url.sh"
echo "=============================================================================================="
echo "Getting Azure Ops Manager VHD URI from Pivnet YML...."
echo "=============================================================================================="
pcf_opsman_image_vhd=$(parseRegionURL "east_us" "pivnet-opsmgr/*Azure.yml")
echo "Found Azure OpsMan Image @ $pcf_opsman_image_vhd ...."
echo $pcf_opsman_image_vhd > opsman-metadata/uri
