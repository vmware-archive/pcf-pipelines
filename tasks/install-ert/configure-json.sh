#!/bin/bash

set -e


# Set Vars
json_file_path="pcf-pipelines/tasks/install-ert/json_templates/${pcf_iaas}/${terraform_template}"
json_file_template="${json_file_path}/ert-template.json"
json_file="json_file/ert.json"

cp ${json_file_template} ${json_file}

if [[ ! -f ${json_file} ]]; then
  echo "Error: cant find file=[${json_file}]"
  exit 1
fi

perl -pi -e "s/{{pcf_az_1}}/${pcf_az_1}/g" ${json_file}
perl -pi -e "s/{{pcf_az_2}}/${pcf_az_2}/g" ${json_file}
perl -pi -e "s/{{pcf_az_3}}/${pcf_az_3}/g" ${json_file}

perl -pi -e "s/{{pcf_ert_domain}}/${pcf_ert_domain}/g" ${json_file}
perl -pi -e "s/{{terraform_prefix}}/${terraform_prefix}/g" ${json_file}

# Test if the ssl cert var from concourse is set to 'generate'.  If so, script will gen a self signed, otherwise will assume its a provided cert
if [[ ${pcf_ert_ssl_cert} == "generate" ]]; then
  echo "=============================================================================================="
  echo "Generating Self Signed Certs for sys.${pcf_ert_domain} & cfapps.${pcf_ert_domain} ..."
  echo "=============================================================================================="
  pcf-pipelines/tasks/install-ert/scripts/ssl/gen_ssl_certs.sh "sys.${pcf_ert_domain}" "cfapps.${pcf_ert_domain}"
  export pcf_ert_ssl_cert=$(cat sys.${pcf_ert_domain}.crt)
  export pcf_ert_ssl_key=$(cat sys.${pcf_ert_domain}.key)
fi

cat > filters <<'EOF'
.properties.properties.".properties.networking_point_of_entry.external_ssl.ssl_rsa_certificate".value = {
  "cert_pem" = $cert_pem,
  "private_key_pem" = $private_key_pem
}
EOF

jq \
  --arg cert_pem "$pcf_ert_ssl_cert" \
  --arg private_key_pem "$pcf_ert_ssl_key" \
  --from-file filters \
  $json_file > config.json

mv config.json $json_file

# Iaas Specific ERT  JSON Edits

if [[ -e pcf-pipelines/tasks/install-ert/scripts/iaas-specific-config/${pcf_iaas}/run.sh ]]; then
  echo "Executing ${pcf_iaas} IaaS specific config ..."
  ./pcf-pipelines/tasks/install-ert/scripts/iaas-specific-config/${pcf_iaas}/run.sh
fi
