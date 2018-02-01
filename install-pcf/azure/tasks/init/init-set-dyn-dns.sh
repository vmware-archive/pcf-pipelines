#!/bin/bash
set -e

if [[ ! $dyn_enabled == true || -z $dyn_enabled ]]; then
  echo "C0 Dyn integration Disabled"
  exit 0
fi

#############################################################
#################### Azure Auth  & functions ##################
#############################################################

az login --service-principal -u ${azure_client_id} -p ${azure_client_secret} --tenant ${azure_tenant_id}

#############################################################
############### Set C0 Dyn DNS             ##################
#############################################################


resgroup_lookup_net=${azure_terraform_prefix}
resgroup_lookup_pcf=${azure_terraform_prefix}

function fn_get_ip {
      # Adding retry logic to this because Azure doesn't always return the IPs on the first attempt
      for (( z=1; z<6; z++ )); do
           sleep 1
           azure_cmd="az network public-ip list -g ${resgroup_lookup_net} --output json | jq '.[] | select( .name | contains(\"${1}\")) | .ipAddress' | tr -d '\"'"
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

function fn_set_dyn_dns {
     curl_cmd="curl \"https://$dyn_user:$dyn_token@members.dyndns.org/v3/update?hostname=$1.$pcf_ert_domain&myip=$2\""
     echo $curl_cmd
     eval $curl_cmd
}

pub_ip_pcf_lb=$(fn_get_ip "web-lb")
pub_ip_tcp_lb=$(fn_get_ip "tcp-lb")
pub_ip_ssh_proxy_lb=$(fn_get_ip "ssh-proxy-lb")
pub_ip_opsman_vm=$(fn_get_ip "opsman")
pub_ip_jumpbox_vm=$(fn_get_ip "jb")
priv_ip_mysql=$(az network lb frontend-ip list -g ${resgroup_lookup_pcf} --lb-name ${azure_terraform_prefix}-mysql-lb --output json | jq -r .[].privateIpAddress)


fn_set_dyn_dns "api" "$pub_ip_pcf_lb"
fn_set_dyn_dns "opsman" "$pub_ip_opsman_vm"
fn_set_dyn_dns "ssh.${system_domain}" "$pub_ip_ssh_proxy_lb"
fn_set_dyn_dns "tcp" "$pub_ip_tcp_lb"
fn_set_dyn_dns "jumpbox" "$pub_ip_jumpbox_vm"
fn_set_dyn_dns "mysql-proxy-lb.${system_domain}" "$priv_ip_mysql"

echo
echo "----------------------------------------------------------------------------------------------"
echo "Sleeping until DNS Cache updates..."
echo "----------------------------------------------------------------------------------------------"


let dns_retries=20
let dns_sleep_seconds=15
for (( z=1; z<${dns_retries}; z++ )); do

    resolve_ip=$(dig opsman.${pcf_ert_domain} | grep -A 1 "ANSWER SECTION" | grep ^opsman | awk '{print$5}')
    if [[ ! $resolve_ip == $pub_ip_opsman_vm ]]; then
      echo "dnsattempt_$z of $dns_retries:DNS not updated yet!!! I expected the new IP of $pub_ip_opsman_vm but got this instead - $resolve_ip"
      sleep $dns_sleep_seconds
    else
      echo "SUCCESS!!! Standard Dyn DNS updated for  ${pcf_ert_domain}"
      exit 0
    fi
done

#echo "FAIL!!! Standard Dyn DNS not updated for  $pcf_ert_domain"
dig opsman.${pcf_ert_domain}

#exit 1
