#!/bin/bash
set -e 

if [[ -z "$ERRANDS_TO_TOGGLE" ]] && [[ -z "$ERRANDS_TO_IGNORE" ]]; then
  echo Nothing to do.
  exit 0
else
  if [[ "$ERRANDS_TO_TOGGLE" == "all" ]] || [[ -z "$ERRANDS_TO_TOGGLE" ]]; then
    errands=$(
      om-linux \
      --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
      --skip-ssl-validation \
      --client-id "${OPSMAN_CLIENT_ID}" \
      --client-secret "${OPSMAN_CLIENT_SECRET}" \
      --username "$OPSMAN_USERNAME" \
      --password "$OPSMAN_PASSWORD" \
      errands \
      --product-name "$PRODUCT_NAME" |
      tail -n+3 |
      awk '{print $2}'
    )
    ERRANDS_TO_TOGGLE='["'$(echo $errands | sed 's/ /\"\,\"/g')'"]'
  fi

  if ! [[ -z "$ERRANDS_TO_IGNORE" ]]; then
  toggle_errands=($(jq -r -n \
    --argjson enabled '{ "errands": '$ERRANDS_TO_TOGGLE'}' \
    --argjson ignore '{ "errands": '$ERRANDS_TO_IGNORE'}' \
    ' $enabled.errands - $ignore.errands | .[] '))
  else
  toggle_errands=($(jq -r -n \
    --argjson enabled '{ "errands": '$ERRANDS_TO_TOGGLE'}' \
    '$enabled.errands | .[]'))
  fi
  IFS=","
  for errand in "${toggle_errands[@]}"; do
    echo "Setting $errand to $ERRAND_STATUS"
    om-linux \
      --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
      --skip-ssl-validation \
      --client-id "${OPSMAN_CLIENT_ID}" \
      --client-secret "${OPSMAN_CLIENT_SECRET}" \
      --username "$OPSMAN_USERNAME" \
      --password "$OPSMAN_PASSWORD" \
      set-errand-state \
      --product-name "$PRODUCT_NAME" \
      --errand-name $errand \
      --post-deploy-state $ERRAND_STATUS
  done
fi

