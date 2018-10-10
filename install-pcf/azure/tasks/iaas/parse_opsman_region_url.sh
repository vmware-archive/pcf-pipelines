#!/bin/bash

function regionMap() {
	regionMap=("west_us" "east_us" "west_europe" "southeast_asia")
}

function parseRegionURL() {
	region_name=$1
	yaml_file_path=$2
	region_map=regionMap
	if [[ -n "${region_map[$region_name]}" ]]; then
		pcf_opsman_image_vhd=$(grep -i "${region_name}:.*.vhd" ${yaml_file_path} | cut -d' ' -f2)
		echo "${pcf_opsman_image_vhd}"
	else
		echo "Not a valid region: ${region_name}"
		exit 1
	fi
}
