#!/bin/bash

sudo apt-get update
sudo apt-get install -y unzip
wget -O terraform.zip https://releases.hashicorp.com/terraform/0.7.11/terraform_0.7.11_linux_amd64.zip
unzip terraform.zip
# if terraform.tfstate file is empty remove the file
if [[ ! -s terraform.tfstate ]]; then
    echo "Removing the terraform.tfstate..."
    rm terraform.tfstate    
fi
chmod a+x terraform
sudo ln terraform /usr/local/bin/terraform

source rds_input.txt

terraform apply

