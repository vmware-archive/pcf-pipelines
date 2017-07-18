############################################################################################################
### name:         config-director-json.sh
### function:     Use curl to automate PCF Opsman Deploys
### use_with:     Opsman 1.8.#
### version:      1.0.0
### last_updated: Oct 2016
### author:       mglynn@pivotal.io
############################################################################################################
############################################################################################################
#!/bin/bash
set -e

############################################################################################################
############################################# Variables  ###################################################
############################################################################################################
provider_type=${1}
config_target=${2}

# Setting exec_mode=LOCAL for debugging, otherise vars get pulled from Concourse
exec_mode="CONCOURSE" # LOCAL|CONCOURSE
  if [[ $exec_mode == "LOCAL" ]]; then
     exec_mode_root="."
     pcf_opsman_admin="admin"
     pcf_opsman_admin_passwd='P1v0t4l!'
     pcf_ert_domain="azure.customer0.net"
     if [[ $provider_type == "azure" ]]; then
       azure_pcf_terraform_template="c0-azure-base"
       azure_subscription_id=""
       azure_tenant_id=""
       azure_service_principal_id=""
       azure_service_principal_password=""
       azure_terraform_prefix=""
       azure_bosh_stg_acct=""
       azure_deployment_stg_acct_wildcard=""
       azure_default_security_group=""
       pcf_ssh_key_pub=""
       azure_ssh_private_key=""
     fi
  else
     exec_mode_root="./pcf-pipelines/install-pcf/azure/json-opsman"
     if [[ -z ${pcf_opsman_admin} || -z ${pcf_opsman_admin} ]]; then
       echo "config-director-json_err: Missing Key Variables!!!!"
       exit 1
     fi
  fi

  json_file_path="${exec_mode_root}/${azure_pcf_terraform_template}"
  opsman_host="opsman.${pcf_ert_domain}"

# Import reqd BASH functions

source ${exec_mode_root}/config-director-json-fn-opsman-curl.sh
source ${exec_mode_root}/config-director-json-fn-opsman-auth.sh
source ${exec_mode_root}/config-director-json-fn-opsman-json-to-post-data.sh
source ${exec_mode_root}/config-director-json-fn-opsman-extensions.sh
source ${exec_mode_root}/config-director-json-fn-opsman-config-director.sh



############################################################################################################
###### Create iaas_configuration JSON                                                                 ######
############################################################################################################
# Detect if SSH keys are set to autogen
if [[ ${pcf_ssh_key_pub} == 'generate' ]]; then
  echo "Generating SSH keys for BOSH deployed VMs"
  ssh-keygen -t rsa -f bosh -C ubuntu -q -P ""
  pcf_ssh_key_pub=$(cat bosh.pub)
  pcf_ssh_key_priv=$(cat bosh)
  echo "******************************"
  echo "******************************"
  echo "pcf_ssh_key_pub = ${pcf_ssh_key_pub}"
  echo "******************************"
  echo "pcf_ssh_key_priv = ${pcf_ssh_key_priv}"
  echo "******************************"
  echo "******************************"
fi


# Set Stg Acct Name Prefix and other Azure constants
  env_short_name=$(echo ${azure_terraform_prefix} | tr -d "-" | tr -d "_" | tr -d "[0-9]")
  env_short_name=$(echo ${env_short_name:0:10})

  azure_bosh_stg_acct="${env_short_name}root"
  azure_deployment_stg_acct_wildcard="*boshvms*"
  azure_default_security_group="pcf-default-security-group"

  pcf_ssh_key_priv=$(echo "${pcf_ssh_key_priv}" | perl -p -e 's/\s+$/\\\\n/g')

if [[ $provider_type == "azure" ]]; then

  # Setting lookup Values when using multiple Resource Group Template
  if [[ ! -z ${azure_multi_resgroup_network} && ${azure_pcf_terraform_template} == "c0-azure-multi-res-group" ]]; then
      resgroup_lookup_net=${azure_multi_resgroup_network}
      resgroup_lookup_pcf=${azure_multi_resgroup_pcf}
  else
      resgroup_lookup_net=${azure_terraform_prefix}
      resgroup_lookup_pcf=${azure_terraform_prefix}
  fi

  iaas_configuration_json=$(echo "{
    \"iaas_configuration[subscription_id]\": \"${azure_subscription_id}\",
    \"iaas_configuration[tenant_id]\": \"${azure_tenant_id}\",
    \"iaas_configuration[client_id]\": \"${azure_service_principal_id}\",
    \"iaas_configuration[client_secret]\": \"${azure_service_principal_password}\",
    \"iaas_configuration[resource_group_name]\": \"${resgroup_lookup_pcf}\",
    \"iaas_configuration[bosh_storage_account_name]\": \"${azure_bosh_stg_acct}\",
    \"iaas_configuration[deployments_storage_account_name]\": \"${azure_deployment_stg_acct_wildcard}\",
    \"iaas_configuration[default_security_group]\": \"${azure_default_security_group}\",
    \"iaas_configuration[ssh_public_key]\": \"${pcf_ssh_key_pub}\",
    \"iaas_configuration[ssh_private_key]\": \"${pcf_ssh_key_priv}\"
  }")
else
  echo "config-director-json_err: Provider Type ${provider_type} not yet supported"
  exit 1
fi


############################################################################################################
############################################# Functions  ###################################################
############################################################################################################

  function fn_urlencode {
     local unencoded=${@}
     encoded=$(echo $unencoded | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg')
     #opsman "=,&,\crlf"" fixes, calls fail with these strings encoded
     encoded=$(echo ${encoded} | sed s'/%3D/=/g')
     encoded=$(echo ${encoded} | sed s'/%26/\&/g')
     encoded=$(echo ${encoded} | sed s'/%0A//g')

     echo ${encoded} | tr -d '\n' | tr -d '\r'
  }

  function fn_err {
     echo "config-director-json_err: ${1:-"Unknown Error"}"
     exit 1
  }

  function fn_run {
     printf "%s " ${@}
     eval "${@}"
     printf " # [%3d]\n" ${?}
  }


############################################################################################################
############################################# Main Logic ###################################################
############################################################################################################

case $config_target in
  "director")
    echo "Starting $config_target config ...."
    echo $iaas_configuration_json | jq .
    fn_config_director
  ;;
  *)
    fn_err "$config_target not enabled"
  ;;
esac


############################################################################################################
#################################################  END  ####################################################
############################################################################################################
