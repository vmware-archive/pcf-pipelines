#!/bin/bash -e

chmod +x tool-om/om-linux

CMD=./tool-om/om-linux

until $(curl --output /dev/null -k --silent --head --fail https://$OPS_MGR_HOST/setup); do
    printf '.'
    sleep 5
done

$CMD -t https://$OPS_MGR_HOST -k configure-authentication -u $OPS_MGR_USR -p $OPS_MGR_PWD -dp $OM_DECRYPTION_PWD
