#!/usr/bin/env bash

set -eu

if [[ -z "$ERRANDS_TO_ENABLE" ]] || [[ "$ERRANDS_TO_ENABLE" == "none" ]]; then
  echo Nothing to do.
  exit 0
fi

disabled_errands=$(
  om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --client-id "${OPSMAN_CLIENT_ID}" \
    --client-secret "${OPSMAN_CLIENT_SECRET}" \
    --username "$OPSMAN_USERNAME" \
    --password "$OPSMAN_PASSWORD" \
    errands \
    --product-name "$PRODUCT_NAME" |
  tail -n+4 | head -n-1 | grep -v true | cut -d'|' -f2 | tr -d ' '
)

if [[ "$ERRANDS_TO_ENABLE" == "all" ]]; then
  errands_to_enable="${disabled_errands[@]}"
else
  errands_to_enable=$(echo "$ERRANDS_TO_ENABLE" | tr ',' '\n')
fi

will_enable=$(
  echo $disabled_errands |
  jq \
    --arg to_enable "${errands_to_enable[@]}" \
    --raw-input \
    --raw-output \
    'split(" ")
    | reduce .[] as $errand ([];
       if $to_enable | contains($errand) then
         . + [$errand]
       else
         .
       end)
    | join("\n")'
)

if [ -z "$will_enable" ]; then
  echo Nothing to do.
  exit 0
fi

while read errand; do
  echo -n Enabling $errand...
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
    --post-deploy-state "enabled"
  echo done
done < <(echo "$will_enable")