#!/bin/bash

set -eu

until $(curl --output /dev/null -k --silent --head --fail https://$OPS_MGR_HOST/setup); do
    printf '.'
    sleep 5
done

om-linux \
  --target https://$OPS_MGR_HOST \
  --skip-ssl-validation \
  configure-authentication \
  --username $OPS_MGR_USR \
  --password $OPS_MGR_PWD \
  --decryption-passphrase $OM_DECRYPTION_PWD
