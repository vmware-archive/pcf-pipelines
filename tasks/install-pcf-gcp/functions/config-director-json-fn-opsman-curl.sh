#!/bin/bash
function fn_opsman_curl() {
  ### Four positional inputs
  ### fn_opsman_curl "[POST|GET]" "[url w/out the proto&host]" "[xuaacsrf]" "[--FORM]"
  ### (1) Curl Action type
  ### (2) Url w/out the proto&host, https is hardcoded & host is a passed variable
  ### (3) if request requires csrf pass it here, otherwise u must pass a null string ""
  ### (4) Request Special Instructions
  ###     "--NOENCODE"  will strip -H "Content-Type: application/x-www-form-urlencoded" from rqst
  ### (5) Json data for POST, -d @
  ### (6) Additonal Curl Args (Optional)

  ####### Curl Core Command Flags #######

  curl_cmd="curl -k -s -i ${6} --cookie mycookiejar --cookie-jar mycookiejar -X $1 "

  ####### Headers #######

  curl_headers="-H \"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\""
  curl_headers="${curl_headers} -H \"Accept-Encoding: gzip, deflate, br\""
  curl_headers="${curl_headers} -H \"Accept-Language: en-US,en;q=0.8\""
  curl_headers="${curl_headers} -H \"Cache-Control: max-age=0\""
  curl_headers="${curl_headers} -H \"Connection: keep-alive\""
  curl_headers="${curl_headers} -H \"Host: ${opsman_host}\""
  curl_headers="${curl_headers} -H \"Upgrade-Insecure-Requests: 1\""


  if [[ $4 != "--NOENCODE" ]]; then
    curl_headers="${curl_headers} -H \"Content-Type: application/x-www-form-urlencoded\""
  fi

  if [[ ($2 == "uaa/login.do" && $1 == "POST") ]]; then
    curl_headers="${curl_headers} -H \"Cookie: X-Uaa-Csrf=$3\""
  fi

  ####### Host URL Builder #######

  curl_host="https://${opsman_host}/${2}"

  ####### Post Form Data Builder #######

  if [[ ! -z ${3} && ${1} == "POST" && ${4} != "--NOENCODE" && ! -z ${5} ]]; then
    if [[ ${2} == *"az_and_network_assignments"* ]]; then
      curl_form_data="-d \"utf8=%E2%9C%93&_method=patch&authenticity_token=${3}${5}\""
    else
      curl_form_data="-d \"utf8=%E2%9C%93&_method=put&authenticity_token=${3}${5}\""
    fi
    echo "Im Gonna use this for data: ${curl_form_data}"
  elif [[ ${1} == "POST" && ! -z ${5} ]]; then
    curl_form_data="${5}"
  else
    echo "NO POST DATA ..."
  fi

  ####### Curl Command Exec Builder #######

  if [[ ${1} == "POST" ]]; then
    cmd=$(echo "${curl_cmd} ${curl_headers} ${curl_form_data} '${curl_host}'" | tr -d '\n' | tr -d '\r')
  else
    cmd=$(echo "${curl_cmd} ${curl_headers} '${curl_host}'" | tr -d '\n' | tr -d '\r')
  fi
  echo "DEBUG_CMD=${cmd}"
  echo "DEBUG_CMD_LEN=${#cmd}"
  fn_run $cmd
}
