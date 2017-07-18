#!/bin/bash
set -e

#############################################################
#################### Azure Auth  & functions ##################
#############################################################


### Grab the OpsManager image name from the PivNet PDF
echo "=============================================================================================="
echo "Getting Azure Ops Manager VHD URI ...."
echo "=============================================================================================="

/usr/bin/pdftotext pivnet-opsmgr/*Azure*.pdf /tmp/opsman.txt
opsman_region="East US"
pcf_opsman_image_vhd=$(grep -i -A 1 "$opsman_region" /tmp/opsman.txt | grep "https")
#pcf_opsman_image_version=$(grep -i -A 1 "$opsman_region" /tmp/opsman.txt | grep "https" | awk -F "ops-manager-" '{print$2}')


echo "Found Azure OpsMan Image @ $pcf_opsman_image_vhd ...."
echo $pcf_opsman_image_vhd > opsman-metadata/uri
