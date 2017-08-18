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
PROVIDER_TYPE=${1}
CONFIG_TARGET=${2}

if [[ -z ${PCF_OPSMAN_ADMIN} || -z ${PCF_OPSMAN_ADMIN_PASSWORD} ]]; then
  echo "config-director-json_err: Missing Key Variables!!!!"
  exit 1
fi

EXEC_MODE_ROOT="./pcf-pipelines/install-pcf/azure/json-opsman"
JSON_FILE_PATH="${EXEC_MODE_ROOT}/${AZURE_PCF_TERRAFORM_TEMPLATE}"

# Import reqd BASH functions

source ${EXEC_MODE_ROOT}/config-director-json-fn-opsman-curl.sh
source ${EXEC_MODE_ROOT}/config-director-json-fn-opsman-auth.sh
source ${EXEC_MODE_ROOT}/config-director-json-fn-opsman-json-to-post-data.sh
source ${EXEC_MODE_ROOT}/config-director-json-fn-opsman-extensions.sh
source ${EXEC_MODE_ROOT}/config-director-json-fn-opsman-config-director.sh



############################################################################################################
###### Create iaas_configuration JSON                                                                 ######
############################################################################################################
# Detect if SSH keys are set to autogen
if [[ ${PCF_SSH_KEY_PUB} == 'generate' ]]; then
  echo "Generating SSH keys for BOSH deployed VMs"
  ssh-keygen -t rsa -f bosh -C ubuntu -q -P ""
  pcf_ssh_key_pub=$(cat bosh.pub)
  pcf_ssh_key_priv=$(cat bosh)
  echo "******************************"
  echo "******************************"
  echo "pcf_ssh_key_pub = ${PCF_SSH_KEY_PUB}"
  echo "******************************"
  echo "pcf_ssh_key_priv = ${PCF_SSH_KEY_PRIV}"
  echo "******************************"
  echo "******************************"
fi


# Set Stg Acct Name Prefix and other Azure constants
  env_short_name=$(echo ${AZURE_TERRAFORM_PREFIX} | tr -d "-" | tr -d "_" | tr -d "[0-9]")
  env_short_name=$(echo ${ENV_SHORT_NAME:0:10})

  azure_bosh_stg_acct="${ENV_SHORT_NAME}root"
  azure_deployment_stg_acct_wildcard="*boshvms*"
  azure_default_security_group="pcf-default-security-group"

  pcf_ssh_key_priv=$(echo "${PCF_SSH_KEY_PRIV}" | perl -p -e 's/\s+$/\\\\n/g')

if [[ ${PROVIDER_TYPE} == "azure" ]]; then

  resgroup_lookup_net=${AZURE_TERRAFORM_PREFIX}
  resgroup_lookup_pcf=${AZURE_TERRAFORM_PREFIX}

  iaas_configuration_json=$(echo "{
    \"iaas_configuration[subscription_id]\": \"${AZURE_SUBSCRIPTION_ID}\",
    \"iaas_configuration[tenant_id]\": \"${AZURE_TENANT_ID}\",
    \"iaas_configuration[client_id]\": \"${AZURE_SERVICE_PRINCIPAL_ID}\",
    \"iaas_configuration[client_secret]\": \"${AZURE_SERVICE_PRINCIPAL_PASSWORD}\",
    \"iaas_configuration[resource_group_name]\": \"${RESGROUP_LOOKUP_PCF}\",
    \"iaas_configuration[bosh_storage_account_name]\": \"${AZURE_BOSH_STG_ACCT}\",
    \"iaas_configuration[deployments_storage_account_name]\": \"${AZURE_DEPLOYMENT_STG_ACCT_WILDCARD}\",
    \"iaas_configuration[default_security_group]\": \"${AZURE_DEFAULT_SECURITY_GROUP}\",
    \"iaas_configuration[ssh_public_key]\": \"${PCF_SSH_KEY_PUB}\",
    \"iaas_configuration[ssh_private_key]\": \"${PCF_SSH_KEY_PRIV}\"
  }")
else
  echo "config-director-json_err: Provider Type ${PROVIDER_TYPE} not yet supported"
  exit 1
fi


############################################################################################################
############################################# Functions  ###################################################
############################################################################################################

  function fn_urlencode {
     local unencoded=${@}
     encoded=$(echo ${unencoded} | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg')
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

case ${config_target} in
  "director")
    echo "Starting ${config_target} config ...."
    echo ${iaas_configuration_json} | jq .
    fn_config_director
  ;;
  *)
    fn_err "${config_target} not enabled"
  ;;
esac


############################################################################################################
#################################################  END  ####################################################
############################################################################################################
