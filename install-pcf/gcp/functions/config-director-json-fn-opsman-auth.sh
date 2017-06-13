#!/bin/bash

function fn_opsman_auth {
  ### No Inputs,   reads from vars set by config-director-json and authenticates to OpsMan

  if [[ -f mycookiejar ]]; then
    rm -rf mycookiejar
  fi
  # GET JSESSIONID
  url_authorize=$(fn_opsman_curl "GET" "auth/cloudfoundry"| grep "Location:" | awk '{print $2}' | sed 's/http.*:443\///')
  chk_session_id=$(fn_opsman_curl "GET" $url_authorize | grep "JSESSIONID" | awk '{print$2}' | awk -F"=" '{print$2}' | tr -d ';')
  cookie_session_id=$(cat mycookiejar | grep "JSESSIONID" | awk '{print$7}')

  # Validate
  if [[ ${chk_session_id} != ${cookie_session_id} || -z ${cookie_session_id} ]]; then
    fn_err "fn_opsman_auth has failed to get a JSESSIONID!!!"
  else
    echo "PASS: fn_opsman_auth get JSESSIONID has succeeded..."
  fi

  # POST Opsman Creds to get redirect for token
  xuaacsrf=$(cat mycookiejar | grep X-Uaa-Csrf | awk '{print$7}')
  rqst_form_data="-d 'username=${pcf_opsman_admin}&password=${pcf_opsman_admin_passwd}&X-Uaa-Csrf=${xuaacsrf}'"
  chk_login=$(fn_opsman_curl "POST" "uaa/login.do" "${xuaacsrf}" "--NOENCODE" "${rqst_form_data}" | grep "Location:" | awk '{print$2}' | awk -F '&' '{print$4}')
  url_authorize_state=$(echo "https://${opsman_host}/${url_authorize}" | awk -F '&' '{print$4}')

  # Validate
  if [[ ! ${chk_login} == ${url_authorize_state} || -z ${chk_login} ]]; then
    echo "chk=$chk_login"
    echo "val=$url_authorize_state"
    fn_err "fn_opsman_auth has failed to login with opsman creds!!!"
  else
    echo "chk=$chk_login"
    echo "val=$url_authorize_state"
    echo "PASS: fn_opsman_auth login with opsman creds succeeded..."
  fi

  # GET uaa token(s)
  url_token=$(fn_opsman_curl "GET" $url_authorize | grep "Location" | awk '{print$2}' | tr -d '\n')
  url_token_code=$(echo $url_token | awk -F "?" '{print$2}' | awk -F '&' '{print$1}' | awk -F '=' '{print$2}' )
  url_token_state=$(echo $url_token | awk -F "?" '{print$2}' | awk -F '&' '{print$2}' | awk -F '=' '{print$2}' )
  url_token=$(echo "auth/cloudfoundry/callback?code=${url_token_code}&state=${url_token_state}")
  chk_uaa_access_token=$(fn_opsman_curl "GET" $url_token "--NOENCODE" | grep "uaa_access_token" | awk '{print$2}' | awk -F ';' '{print$1}' | sed 's/uaa_access_token=//')
  cookie_uaa_access_token=$(cat mycookiejar | grep "uaa_access_token" | awk '{print$7}')

  # Validate
  if [[ ${chk_uaa_access_token} != ${cookie_uaa_access_token} || -z ${chk_uaa_access_token} ]]; then
    echo "chk_uaa_access_token=${chk_uaa_access_token}"
    echo "cookie_uaa_access_token=${cookie_uaa_access_token}"
    fn_err "fn_opsman_auth has failed to get proper uaa tokens!!!"
  else
    #echo "chk_uaa_access_token=${chk_uaa_access_token}"
    #echo "cookie_uaa_access_token=${cookie_uaa_access_token}"
    echo "PASS: fn_opsman_auth get proper uaa tokens succeeded..."
  fi
}
