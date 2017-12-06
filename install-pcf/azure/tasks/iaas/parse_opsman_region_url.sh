#!/bin/bash

function parseRegionURL () {
     region_name=$1
     yaml_file_path=$2
     pcf_opsman_image_vhd=$(grep -i "${region_name}:.*.vhd" ${yaml_file_path} | cut -d' ' -f2)
     echo "${pcf_opsman_image_vhd}"
}
