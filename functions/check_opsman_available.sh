function check_opsman_available {
  local opsman_domain=$1

  if [[ -z $(dig +short $opsman_domain) ]]; then
    echo "unavailable"
    return
  fi

  status_code=$(curl -L -s -o /dev/null -w "%{http_code}" -k "https://${opsman_domain}/login/ensure_availability")
  if [[ $status_code != 200 ]]; then
    echo "unavailable"
    return
  fi

  echo "available"
}
