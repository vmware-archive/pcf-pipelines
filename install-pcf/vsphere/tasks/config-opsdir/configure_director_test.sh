#!/bin/bash

function TestCallToDirectorIaasConfigShouldContainNSXElements () (
  helperLoadDefaultEnvVars
  NSX_NETWORKING_ENABLED=true
  NSX_ADDRESS="sample-address"
  NSX_USERNAME="some-user"
  NSX_PASSWORD="super-secret"
  NSX_CA_CERTIFICATE="double-super-secret"
  config_file=$(mktemp)

  function om-linux () {
    local iaas_config=$(omLinuxSpy "$@")
    if [[ ${iaas_config// } != "" ]]; then
      echo "${iaas_config// }" >> ${config_file}
    fi
  }
  (configure_director)
  config_json=$(cat "${config_file}" && rm -fr "${config_file}")

  if [[ ${config_json} == "" ]]; then
    return $(Expect "${config_json}" ToNotBe "")
  fi

  (echo "${config_json}" | \
    jq -e \
    --arg enabled ${NSX_NETWORKING_ENABLED} \
    --arg address "${NSX_ADDRESS}" \
    --arg user "${NSX_USERNAME}" \
    --arg pass "${NSX_PASSWORD}" \
    --arg cert "${NSX_CA_CERTIFICATE}" \
    'select(.nsx_networking_enabled) |
    select(.nsx_address == $address) |
    select(.nsx_username == $user) |
    select(.nsx_password == $pass) |
    select(.nsx_ca_certificate == $cert)')
  exitcode=$?
  return $(Expect $exitcode ToBe 0)
)

# this spies on calls to om-linux checking for
# any flags matching `--iaas-configuration`
# if found it will return the value for the flag
# which should be the iaas config json
function omLinuxSpy () {
  local printargval=false

  for i in "$@"; do
    if $printargval; then
      echo $i
      local printargval=false
    fi
    if [[ $i == "--iaas-configuration" ]]; then
      local printargval=true
    fi
  done
}

# loads up some defaults which need to be
# set in order for jq parsing to not throw
# errors
function helperLoadDefaultEnvVars () {
  set +u
  ICMP_CHECKS_ENABLED="{}"
  IS_SERVICE_NETWORK="{}"
}
