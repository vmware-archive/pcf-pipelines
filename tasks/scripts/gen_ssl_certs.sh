#!/bin/bash
#mglynn@pivotal.io

set -e

SYS_DOMAIN=$1
APP_DOMAIN=$2
VIP=$3

SSL_FILE=sslconf-${SYS_DOMAIN}.conf

#Generate SSL Config with SANs
if [ ! -f $SSL_FILE ]; then
 cat > $SSL_FILE <<EOM
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
#countryName = Country Name (2 letter code)
#countryName_default = US
#stateOrProvinceName = State or Province Name (full name)
#stateOrProvinceName_default = TX
#localityName = Locality Name (eg, city)
#localityName_default = Frisco
#organizationalUnitName     = Organizational Unit Name (eg, section)
#organizationalUnitName_default   = Pivotal Labs
#commonName = Pivotal
#commonName_max = 64
[ v3_req ]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.${SYS_DOMAIN}
#IP.1 = ${VIP}
DNS.2 = *.login.${SYS_DOMAIN}
#IP.2 = ${VIP}
DNS.3 = *.uaa.${SYS_DOMAIN}
#IP.3 = ${VIP}
DNS.4 = *.${APP_DOMAIN}
#IP.4 = ${VIP}
EOM
fi

openssl genrsa -out ${SYS_DOMAIN}.key 2048
openssl req -new -out ${SYS_DOMAIN}.csr -subj "/CN=*.${SYS_DOMAIN}/O=Pivotal/C=US" -key ${SYS_DOMAIN}.key -config ${SSL_FILE}
openssl req -text -noout -in ${SYS_DOMAIN}.csr
openssl x509 -req -days 3650 -in ${SYS_DOMAIN}.csr -signkey ${SYS_DOMAIN}.key -out ${SYS_DOMAIN}.crt -extensions v3_req -extfile ${SSL_FILE}
openssl x509 -in ${SYS_DOMAIN}.crt -text -noout
