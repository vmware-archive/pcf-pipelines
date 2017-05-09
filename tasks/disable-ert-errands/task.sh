#!/bin/bash -e

chmod +x tool-om/om-linux
CMD=./tool-om/om-linux

ERT_ERRANDS=$(cat <<-EOF
{"errands": [
  {"name": "smoke-tests","post_deploy": false},
  {"name": "push-apps-manager","post_deploy": false},
  {"name": "notifications","post_deploy": false},
  {"name": "notifications-ui","post_deploy": false},
  {"name": "push-pivotal-account","post_deploy": false},
  {"name": "autoscaling","post_deploy": false},
  {"name": "autoscaling-register-broker","post_deploy": false}
]}
EOF
)

CF_GUID=`$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/deployed/products" -x GET | jq '.[] | select(.installation_name | contains("cf-")) | .guid' | tr -d '"'`

$CMD -t https://$OPS_MGR_HOST -k -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -p "/api/v0/staged/products/$CF_GUID/errands" -x PUT -d "$ERT_ERRANDS"
