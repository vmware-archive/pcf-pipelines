#!/bin/bash
set -e

# Copy base template with no clobber if not using the base template
if [[ ! ${azure_pcf_terraform_template} == "c0-azure-base" ]]; then
  cp -rn pcf-pipelines/install-pcf/azure/terraform/c0-azure-base/* pcf-pipelines/install-pcf/azure/terraform/${azure_pcf_terraform_template}/
fi

echo "=============================================================================================="
echo "Collecting Terraform Variables from Deployed Azure Objects ...."
echo "=============================================================================================="

# Get Opsman VHD from previous task
pcf_opsman_image_uri=$(cat opsman-metadata/uri)

# Get Public IPs
azure login --service-principal -u ${azure_service_principal_id} -p ${azure_service_principal_password} --tenant ${azure_tenant_id}
azure account set ${azure_subscription_id}

resgroup_lookup_net=${azure_terraform_prefix}
resgroup_lookup_pcf=${azure_terraform_prefix}
subnet_lookup_infra="${azure_terraform_prefix}-opsman-and-director-subnet"
vnet_lookup="${azure_terraform_prefix}-virtual-network"

### IP Functions

function fn_get_ip {
      # Adding retry logic to this because Azure doesn't always return the IPs on the first attempt
      for (( z=1; z<6; z++ )); do
           sleep 1
           azure_cmd="azure network public-ip list -g ${resgroup_lookup_net} --json | jq '.[] | select( .name | contains(\"${1}\")) | .ipAddress' | tr -d '\"'"
           pub_ip=$(eval $azure_cmd)

           if [[ -z ${pub_ip} ]]; then
             echo "Attempt $z of 5 failed to get an IP Address value returned from Azure cli" 1>&2
           else
             echo ${pub_ip}
             return 0
           fi
      done

     if [[ -z ${pub_ip} ]]; then
       echo "I couldnt get any ip from Azure CLI for ${1}"
       exit 1
     fi
}

function fn_get_ip_ref_id {
     azure_cmd="azure network public-ip list -g ${resgroup_lookup_net} --json | jq '.[] | select( .name | contains(\"${1}\")) | .id' | tr -d '\"'"
     pub_ip=$(eval $azure_cmd)
     echo $pub_ip
}

function fn_get_subnet_id {
     azure_cmd="azure network vnet subnet list -g ${resgroup_lookup_net} -e ${vnet_lookup} --json | jq '.[] | select(.name == \"${subnet_lookup_infra}\") | .id' | awk -F \"/\" '{print$3}'"
     subnet_id=$(eval $azure_cmd)
     echo $subnet_id
}

# Collect Public IPs
pub_ip_pcf_lb=$(fn_get_ip "web-lb")
pub_ip_tcp_lb=$(fn_get_ip "tcp-lb")
pub_ip_ssh_proxy_lb=$(fn_get_ip "ssh-proxy-lb")
priv_ip_mysql_lb=$(azure network lb frontend-ip list -g ${resgroup_lookup_pcf} -l ${azure_terraform_prefix}-mysql-lb --json | jq .[].privateIPAddress | tr -d '"')

pub_ip_opsman_vm=$(fn_get_ip "opsman")
pub_ip_jumpbox_vm=$(fn_get_ip "jb")


# Collect Public IPs reference IDs for Terraform
pub_ip_id_pcf_lb=$(fn_get_ip_ref_id "web-lb")
pub_ip_id_tcp_lb=$(fn_get_ip_ref_id "tcp-lb")
pub_ip_id_ssh_proxy_lb=$(fn_get_ip_ref_id "ssh-proxy-lb")
pub_ip_id_opsman_vm=$(fn_get_ip_ref_id "opsman")
pub_ip_id_jumpbox_vm=$(fn_get_ip_ref_id "jb")

# Get the Opsman Subnet ID
subnet_infra_id=$(fn_get_subnet_id ${subnet_lookup_infra})

# Exit if vars fail to set

if [[ -z ${pub_ip_pcf_lb} || -z ${pub_ip_opsman_vm} || -z ${pub_ip_id_pcf_lb} || -z ${subnet_infra_id} ]]; then
  echo "One or More Azure Variables have not set!!!"
  exit 1
fi

# Use prefix to strip down a Storage Account Prefix String
env_short_name=$(echo ${azure_terraform_prefix} | tr -d "-" | tr -d "_" | tr -d "[0-9]")
env_short_name=$(echo ${env_short_name:0:10})

##########################################################
# Terraforming
##########################################################

# Install Terraform cli until we can update the Docker image
wget $(wget -q -O- https://www.terraform.io/downloads.html | grep linux_amd64 | awk -F '"' '{print$2}') -O /tmp/terraform.zip
if [ -d /opt/terraform ]; then
  rm -rf /opt/terraform
fi

unzip /tmp/terraform.zip
sudo cp terraform /usr/local/bin
export PATH=/opt/terraform/terraform:$PATH

##########################################################
# Detect generate for ssh keys
##########################################################

if [[ ${pcf_ssh_key_pub} == 'generate' ]]; then
  echo "Generating SSH keys for Opsman"
  ssh-keygen -t rsa -f opsman -C ubuntu -q -P ""
  pcf_ssh_key_pub=$(cat opsman.pub)
  pcf_ssh_key_priv=$(cat opsman)
  echo "******************************"
  echo "******************************"
  echo "pcf_ssh_key_pub = ${pcf_ssh_key_pub}"
  echo "******************************"
  echo "pcf_ssh_key_priv = ${pcf_ssh_key_priv}"
  echo "******************************"
  echo "******************************"
fi

function fn_exec_tf {
  echo "=============================================================================================="
  echo "Executing Terraform ${1} ..."
  echo "=============================================================================================="

  terraform ${1} \
    -var "subscription_id=${azure_subscription_id}" \
    -var "client_id=${azure_service_principal_id}" \
    -var "client_secret=${azure_service_principal_password}" \
    -var "tenant_id=${azure_tenant_id}" \
    -var "location=${azure_region}" \
    -var "env_name=${azure_terraform_prefix}" \
    -var "env_short_name=${env_short_name}" \
    -var "dns_suffix=${pcf_ert_domain}" \
    -var "pub_ip_pcf_lb=${pub_ip_pcf_lb}" \
    -var "pub_ip_id_pcf_lb=${pub_ip_id_pcf_lb}" \
    -var "pub_ip_tcp_lb=${pub_ip_tcp_lb}" \
    -var "pub_ip_id_tcp_lb=${pub_ip_id_tcp_lb}" \
    -var "priv_ip_mysql_lb=${priv_ip_mysql_lb}" \
    -var "pub_ip_ssh_proxy_lb=${pub_ip_ssh_proxy_lb}" \
    -var "pub_ip_id_ssh_proxy_lb=${pub_ip_id_ssh_proxy_lb}" \
    -var "pub_ip_opsman_vm=${pub_ip_opsman_vm}" \
    -var "pub_ip_id_opsman_vm=${pub_ip_id_opsman_vm}" \
    -var "pub_ip_jumpbox_vm=${pub_ip_jumpbox_vm}" \
    -var "pub_ip_id_jumpbox_vm=${pub_ip_id_jumpbox_vm}" \
    -var "subnet_infra_id=${subnet_infra_id}" \
    -var "ops_manager_image_uri=${pcf_opsman_image_uri}" \
    -var "vm_admin_username=${azure_vm_admin}" \
    -var "vm_admin_password=${azure_vm_password}" \
    -var "vm_admin_public_key=${pcf_ssh_key_pub}" \
    -var "azure_multi_resgroup_network=${e_multi_resgroup_network}" \
    -var "azure_multi_resgroup_pcf=${azure_multi_resgroup_pcf}" \
    -var "priv_ip_opsman_vm=${azure_terraform_opsman_priv_ip}" \
    -var "azure_account_name=${azure_account_name}" \
    -var "azure_buildpacks_container=${azure_buildpacks_container}" \
    -var "azure_droplets_container=${azure_droplets_container}" \
    -var "azure_packages_container=${azure_packages_container}" \
    -var "azure_resources_container=${azure_resources_container}" \
    pcf-pipelines/install-pcf/azure/terraform/$azure_pcf_terraform_template
}

fn_exec_tf "plan"
fn_exec_tf "apply"
