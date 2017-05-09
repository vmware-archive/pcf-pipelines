function fn_urlencode {
  local unencoded=${@}
  encoded=$(echo $unencoded | perl -pe's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg')
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
