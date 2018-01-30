function generate_cert () (
  set -eu
  local domains="$1"

  local data=$(echo $domains | jq --raw-input -c '{"domains": (. | split(" "))}')

  local response=$(
    om-linux \
      --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
      --client-id "${OPSMAN_CLIENT_ID}" \
      --client-secret "${OPSMAN_CLIENT_SECRET}" \
      --username "$OPS_MGR_USR" \
      --password "$OPS_MGR_PWD" \
      --skip-ssl-validation \
      curl \
      --silent \
      --path "/api/v0/certificates/generate" \
      -x POST \
      -d $data
    )

  echo "$response"
)
