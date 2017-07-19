#!/bin/bash
set -e

echo "=============================================================================================="
echo "Executing Terraform ...."
echo "=============================================================================================="

# Copy base template with no clobber if not using the base template
if [[ ! ${azure_pcf_terraform_template} == "c0-azure-base" ]]; then
  cp -rn pcf-pipelines/install-pcf/azure/terraform/c0-azure-base/* pcf-pipelines/install-pcf/azure/terraform/${azure_pcf_terraform_template}/
fi

# Get ert subnet if multi-resgroup

azure login --service-principal -u ${azure_service_principal_id} -p ${azure_service_principal_password} --tenant ${azure_tenant_id}
azure account set ${azure_subscription_id}
ert_subnet_cmd="azure network vnet subnet list -g network-core  -e vnet-pcf --json | jq '.[] | select(.name == \"ert\") | .id' | tr -d '\"'"
ert_subnet=$(eval $ert_subnet_cmd)
echo "Found SubnetID=${ert_subnet}"


# Install Terraform cli until we can update the Docker image
wget $(wget -q -O- https://www.terraform.io/downloads.html | grep linux_amd64 | awk -F '"' '{print$2}') -O /tmp/terraform.zip
if [ -d /opt/terraform ]; then
  rm -rf /opt/terraform
fi

unzip /tmp/terraform.zip
sudo cp terraform /usr/local/bin
export PATH=/opt/terraform/terraform:$PATH

function fn_terraform {

terraform ${1} \
  -var "subscription_id=${azure_subscription_id}" \
  -var "client_id=${azure_service_principal_id}" \
  -var "client_secret=${azure_service_principal_password}" \
  -var "tenant_id=${azure_tenant_id}" \
  -var "location=${azure_region}" \
  -var "env_name=${azure_terraform_prefix}" \
  -var "azure_terraform_vnet_cidr=${azure_terraform_vnet_cidr}" \
  -var "azure_terraform_subnet_infra_cidr=${azure_terraform_subnet_infra_cidr}" \
  -var "azure_terraform_subnet_ert_cidr=${azure_terraform_subnet_ert_cidr}" \
  -var "azure_terraform_subnet_services1_cidr=${azure_terraform_subnet_services1_cidr}" \
  -var "azure_terraform_subnet_dynamic_services_cidr=${azure_terraform_subnet_dynamic_services_cidr}" \
  -var "ert_subnet_id=${ert_subnet}" \
  -var "azure_multi_resgroup_network=${azure_multi_resgroup_network}" \
  -var "azure_multi_resgroup_pcf=${azure_multi_resgroup_pcf}" \
  pcf-pipelines/install-pcf/azure/terraform/${azure_pcf_terraform_template}/init

}

fn_terraform "plan"
fn_terraform "apply"


echo "=============================================================================================="
echo "This azure_pcf_terraform_template has an 'Init' set of terraform that has pre-created IPs..."
echo "=============================================================================================="


azure login --service-principal -u ${azure_service_principal_id} -p ${azure_service_principal_password} --tenant ${azure_tenant_id}

resgroup_lookup_net=${azure_terraform_prefix}
resgroup_lookup_pcf=${azure_terraform_prefix}

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

pub_ip_pcf_lb=$(fn_get_ip "web-lb")
pub_ip_tcp_lb=$(fn_get_ip "tcp-lb")
pub_ip_ssh_proxy_lb=$(fn_get_ip "ssh-proxy-lb")
pub_ip_opsman_vm=$(fn_get_ip "opsman")
pub_ip_jumpbox_vm=$(fn_get_ip "jb")

priv_ip_mysql=$(azure network lb frontend-ip list -g ${resgroup_lookup_pcf} -l ${azure_terraform_prefix}-mysql-lb --json | jq .[].privateIPAddress | tr -d '"')


echo "You have now deployed Public IPs to azure that must be resolvable to:"
echo "----------------------------------------------------------------------------------------------"
echo "*.sys.${pcf_ert_domain} == ${pub_ip_pcf_lb}"
echo "*.cfapps.${pcf_ert_domain} == ${pub_ip_pcf_lb}"
echo "ssh.sys.${pcf_ert_domain} == ${pub_ip_ssh_proxy_lb}"
echo "tcp.${pcf_ert_domain} == ${pub_ip_tcp_lb}"
echo "opsman.${pcf_ert_domain} == ${pub_ip_opsman_vm}"
echo "jumpbox.${pcf_ert_domain} == ${pub_ip_jumpbox_vm}"
echo "mysql-proxy-lb.sys.${pcf_ert_domain} == ${priv_ip_mysql}"
echo "----------------------------------------------------------------------------------------------"
echo "Do Not Start the 'deploy-iaas' Concourse Job of this Pipeline until you have confirmed that DNS is reolving correctly.  Failure to do so will result in a FAIL!!!!"
