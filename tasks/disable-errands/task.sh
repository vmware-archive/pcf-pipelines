#!/bin/bash

set -eu

errands=''

if [[ "$ERRANDS_TO_DISABLE" == "all" ]]; then
  errands=$(
    om-linux \
    --target "https://${OPSMAN_URI}" \
    --skip-ssl-validation \
    --username "$OPSMAN_USERNAME" \
    --password "$OPSMAN_PASSWORD" \
    errands \
    --product-name "$PRODUCT_NAME" |
    tail -n+4 | head -n-1 | grep "true" | cut -d'|' -f2 | tr -d ' '
  )
elif [[ "$ERRANDS_TO_DISABLE" != "" ]] && [[ "$ERRANDS_TO_DISABLE" != "none" ]]; then
  errands=$(echo "$ERRANDS_TO_DISABLE" | tr ',' '\n')
fi

if [[ -z "$errands" ]]; then
  echo Nothing to do.
  exit 0
fi

while read errand; do
  echo -n Disabling $errand...
  om-linux \
    --target "https://${OPSMAN_URI}" \
    --skip-ssl-validation \
    --username "$OPSMAN_USERNAME" \
    --password "$OPSMAN_PASSWORD" \
    set-errand-state \
    --product-name "$PRODUCT_NAME" \
    --errand-name $errand \
    --post-deploy-state "disabled"
  echo done
done < <(echo "$errands")
