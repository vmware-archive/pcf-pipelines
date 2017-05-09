#!/bin/bash

function fn_config_director {

  declare -a POSTS_DIRECTOR=(
  "iaas_configuration:var"
  "director_configuration:file"
  "availability_zones:file"
  "networks:file"
  "az_and_network_assignment:file"
  "resources:file"
  )

  for x in ${POSTS_DIRECTOR[@]}; do
    POSTS_PAGE=$(echo $x | awk -F ":" '{print$1}')
    POSTS_JSON_TYPE=$(echo $x | awk -F ":" '{print$2}')

    # set GET Page url so we can Grab a csrf token or do other variable collection
    if [[ $POSTS_PAGE == "az_and_network_assignment" ]]; then
      GET_PAGE="infrastructure/director/az_and_network_assignment/edit"
    elif [[ $POSTS_PAGE == "resources" ]]; then
      GET_PAGE="infrastructure/director/resources/edit"
    else
      GET_PAGE="infrastructure/$POSTS_PAGE/edit"
    fi

    echo "####################################################################"
    echo "GETTING JSON FOR: DIRECTOR -> $POSTS_PAGE <- $POSTS_JSON_TYPE ..."
    echo "####################################################################"
    post_data=$(fn_json_to_post_data $POSTS_PAGE $POSTS_JSON_TYPE "opsman")
    post_data=$(fn_urlencode ${post_data})

    # Auth to Opsman
    fn_opsman_auth
    csrf_token=$(fn_opsman_curl "GET" "${GET_PAGE}" | grep csrf-token | awk '{print$3}' | sed 's/content=\"//' | sed 's/\"$//')

    # Verify we have a current csrf-token
    if [[ -z ${csrf_token} ]]; then
      fn_err "fn_config_director has failed to get csrf_token!!!"
    else
      echo "csrf_token=${csrf_token}"
      ## CSRF Tokens with '=' need to be re-urlencoded back to %3D
      csrf_encoded_token=$(fn_urlencode ${csrf_token} | sed 's|\=|%3D|g')
      echo "csrf_encoded_token=${csrf_encoded_token}"
    fi

    ## Push Config & director_configuration[director_hostname]
    echo "####################################################################"
    echo "PUSHING CONFIG FOR: DIRECTOR -> $POSTS_PAGE <- $POSTS_JSON_TYPE ..."
    echo "####################################################################"

    # set POST Page url so we can push config
    if [[ $POSTS_PAGE == "networks" ]]; then
      POSTS_PAGE="infrastructure/$POSTS_PAGE/update"
    elif [[ $POSTS_PAGE == "az_and_network_assignment" || $POSTS_PAGE == "resources" ]]; then
      POSTS_PAGE="infrastructure/director/$POSTS_PAGE"
    else
      POSTS_PAGE="infrastructure/$POSTS_PAGE"
    fi

    chk_push=$(fn_opsman_curl "POST" "$POSTS_PAGE" "${csrf_encoded_token}" "" "${post_data}" 2>&1 )
    echo ${chk_push}

  done
}
