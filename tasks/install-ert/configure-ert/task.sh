#!/bin/bash
set -e

json_file="json_file/ert.json"

if [[ ! -f ${json_file} ]]; then
  echo "Error: cant find file=[${json_file}]"
  exit 1
fi

function fn_om_linux_curl_fail {
    echo ERROR
    echo stdout:\n
    cat /tmp/rqst_stdout.log >&2
    echo
    echo stderr:\n
    cat /tmp/rqst_stderr.log >&2
}

function fn_om_linux_curl {
  local curl_method=$1
  local curl_path=$2
  local curl_data=$3

  args="--target https://opsman.$pcf_ert_domain -k \
    --username $pcf_opsman_admin \
    --password $pcf_opsman_admin_passwd  \
    curl \
    --request $curl_method \
    --path $curl_path"

  rm -f /tmp/rqst_stdout.log /tmp/rqst_stderr.log

  set +e
  if [ -n "$curl_data" ]; then
    om-linux ${args} --data "${curl_data// /\\ }" 1> /tmp/rqst_stdout.log 2> /tmp/rqst_stderr.log
  else
    om-linux ${args} 1> /tmp/rqst_stdout.log 2> /tmp/rqst_stderr.log
  fi

  if [ $? -ne 0 ]; then
    fn_om_linux_curl_fail
    exit 1
  fi

  grep -s -q "Status: 200 OK" /tmp/rqst_stderr.log
  if [ $? -ne 0 ]; then
    fn_om_linux_curl_fail
    exit 1
  fi

  set -e
  cat /tmp/rqst_stdout.log
}

echo "=============================================================================================="
echo "Deploying ERT @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="
# Get cf Product Guid
guid_cf=$(fn_om_linux_curl "GET" "/api/v0/staged/products" \
            | jq --raw-output '.[] | select(.type == "cf") | .guid' | grep "cf-.*")

echo "=============================================================================================="
echo "Found ERT Deployment with guid of ${guid_cf}"
echo "=============================================================================================="

# Set Networks & AZs
echo "=============================================================================================="
echo "Setting Availability Zones & Networks for: ${guid_cf}"
echo "=============================================================================================="

json_net_and_az=$(cat ${json_file} | jq -c .networks_and_azs)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_cf}/networks_and_azs" "$json_net_and_az"

# Set ERT Properties
echo "=============================================================================================="
echo "Setting Properties for: ${guid_cf}"
echo "=============================================================================================="

json_properties=$(cat ${json_file} | jq -c .properties)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_cf}/properties" "$json_properties"

# Set Resource Configs
echo "=============================================================================================="
echo "Setting Resource Job Properties for: ${guid_cf}"
echo "=============================================================================================="
json_jobs_configs=$(cat ${json_file} | jq .jobs )
json_job_guids=$(fn_om_linux_curl "GET" "/api/v0/staged/products/${guid_cf}/jobs" | jq .)
opsman_avail_jobs=$(echo ${json_job_guids} | jq --raw-output '.jobs[].name')

#for job in $(echo ${json_jobs_configs} | jq . | jq 'keys' | jq .[] | tr -d '"'); do
for job in ${opsman_avail_jobs}; do

 json_job_guid_cmd="echo \${json_job_guids} | jq --raw-output '.jobs[] | select(.name == \"${job}\") | .guid'"
 json_job_guid=$(eval ${json_job_guid_cmd})
 json_job_config_cmd="echo \${json_jobs_configs} | jq -c '.[\"${job}\"]' "
 json_job_config=$(eval ${json_job_config_cmd})
 echo "---------------------------------------------------------------------------------------------"
 echo "Setting ${json_job_guid} with --data=${json_job_config}..."
 fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_cf}/jobs/${json_job_guid}/resource_config" "${json_job_config}"

done
