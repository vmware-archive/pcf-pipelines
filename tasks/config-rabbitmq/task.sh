#!/bin/bash -e

#mv tool-om/om-linux-* tool-om/om-linux
chmod +x tool-om/om-linux
CMD=./tool-om/om-linux

RELEASE=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k available-products | grep p-rabbitmq`

PRODUCT_NAME=`echo $RELEASE | cut -d"|" -f2 | tr -d " "`
PRODUCT_VERSION=`echo $RELEASE | cut -d"|" -f3 | tr -d " "`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

OTHER_AZS=$(fn_other_azs $OTHER_JOB_AZS)

NETWORK=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$SINGLETON_JOB_AZ"
  },
  "other_availability_zones": [
    $OTHER_AZS
  ],
  "network": {
    "name": "$NETWORK_NAME"
  }
}
EOF
)


#
#    ".rabbitmq-server.rsa_certificate": {
#      "value": {
#        "private_key_pem": "$PRIVATE_KEY_PEM",
#        "cert_pem": "$CERT_PEM"
#      }
#    },
PROPERTIES=$(cat <<-EOF
{
    ".rabbitmq-server.plugins": {
      "value": [
        "rabbitmq_management"
      ]
    },
    ".rabbitmq-server.server_admin_credentials": {
      "value": {
        "identity": "$RABBITMQ_ADMIN",
        "password": "$RABBITMQ_PW"
      }
    },
    ".rabbitmq-server.ssl_cacert": {
      "value": null
    },
    ".rabbitmq-server.ssl_verify": {
      "value": $SSL_VERIFY 
    },
    ".rabbitmq-server.ssl_verification_depth": {
      "value": $SSL_VERIFY_DEPTH
    },
    ".rabbitmq-server.ssl_fail_if_no_peer_cert": {
      "value": $SSL_FAIL_IF_NO_PEER_CERT
    },
    ".rabbitmq-server.cookie": {
      "value": null
    },
    ".rabbitmq-server.config": {
      "value": null
    },
    ".properties.metrics_tls_disabled": {
      "value": false
    },
    ".properties.syslog_address": {
      "value": "$SYSLOG_HOST"
    },
    ".properties.syslog_port": {
      "value": $SYSLOG_PORT
    }
}
EOF
)

RESOURCES=$(cat <<-EOF
{
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$PROPERTIES" -pn "$NETWORK" -pr "$RESOURCES"
