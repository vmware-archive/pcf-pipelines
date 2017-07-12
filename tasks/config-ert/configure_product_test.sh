#!/bin/bash

set +ue

function TestProductPropertiesShouldNotContainNSXConfigWhenNSXLBValuesNotSet () (
  helperLoadDefaultEnvVars
  config_file=$(mktemp)
  function om-linux () {
    local product_properties=$(omLinuxSpy "$@")
    if [[ ${product_properties// } != "" ]]; then
      echo "${product_properties// }" > ${config_file}
    fi
  }
  (main)
  config_json=$(cat "${config_file}" && rm -fr "${config_file}")
  (echo "${config_json}" | \
    jq -e \
    '
      select( (.tcp_router.nsx_security_groups | length) == 0) |
      select( .tcp_router.nsx_lbs == null) |
      select( (.router.nsx_security_groups | length) == 0) |
      select( .router.nsx_lbs == null) |
      select( (.diego_brain.nsx_security_groups | length) == 0) |
      select( .diego_brain.nsx_lbs == null)
    ')

  exitcode=$?
  return $(Expect $exitcode ToBe 0)
)

function TestProductPropertiesShouldContainNSXConfigWhenNSXValuesAreSet () (
  helperLoadDefaultEnvVars
  TCP_ROUTER_NSX_SECURITY_GROUP="tcp_sg"
  TCP_ROUTER_NSX_LB_EDGE_NAME="tcp-edge"
  TCP_ROUTER_NSX_LB_POOL_NAME="tcp-pool"
  TCP_ROUTER_NSX_LB_SECURITY_GROUP="tcp_lb_sg"
  TCP_ROUTER_NSX_LB_PORT=8000
  ROUTER_NSX_SECURITY_GROUP="router_sg"
  ROUTER_NSX_LB_EDGE_NAME="router_edge"
  ROUTER_NSX_LB_POOL_NAME="router_pool"
  ROUTER_NSX_LB_SECURITY_GROUP="router_lb_sg"
  ROUTER_NSX_LB_PORT=8001
  DIEGO_BRAIN_NSX_SECURITY_GROUP="diego_sg"
  DIEGO_BRAIN_NSX_LB_EDGE_NAME="diego_edge"
  DIEGO_BRAIN_NSX_LB_POOL_NAME="diego_pool"
  DIEGO_BRAIN_NSX_LB_SECURITY_GROUP="diego_lb_sg"
  DIEGO_BRAIN_NSX_LB_PORT=8002
  config_file=$(mktemp)
  function om-linux () {
    local product_properties=$(omLinuxSpy "$@")
    if [[ ${product_properties// } != "" ]]; then
      echo "${product_properties// }" > ${config_file}
    fi
  }
  (main)
  config_json=$(cat "${config_file}" && rm -fr "${config_file}")
  (echo "${config_json}" | \
    jq -e \
    --arg tcp_sg "${TCP_ROUTER_NSX_SECURITY_GROUP}" \
    --arg tcp_edge "${TCP_ROUTER_NSX_LB_EDGE_NAME}" \
    --arg tcp_pool "${TCP_ROUTER_NSX_LB_POOL_NAME}" \
    --arg tcp_lb_sg "${TCP_ROUTER_NSX_LB_SECURITY_GROUP}" \
    --arg tcp_port "${TCP_ROUTER_NSX_LB_PORT}" \
    --arg router_sg "${ROUTER_NSX_SECURITY_GROUP}" \
    --arg router_edge "${ROUTER_NSX_LB_EDGE_NAME}" \
    --arg router_pool "${ROUTER_NSX_LB_POOL_NAME}" \
    --arg router_lb_sg "${ROUTER_NSX_LB_SECURITY_GROUP}" \
    --arg router_port "${ROUTER_NSX_LB_PORT}" \
    --arg diego_sg "${DIEGO_BRAIN_NSX_SECURITY_GROUP}" \
    --arg diego_edge "${DIEGO_BRAIN_NSX_LB_EDGE_NAME}" \
    --arg diego_pool "${DIEGO_BRAIN_NSX_LB_POOL_NAME}" \
    --arg diego_lb_sg "${DIEGO_BRAIN_NSX_LB_SECURITY_GROUP}" \
    --arg diego_port "${DIEGO_BRAIN_NSX_LB_PORT}" \
    'select(.tcp_router.nsx_security_groups[0] == $tcp_sg) |
      select(.tcp_router.nsx_lbs.edge_name == $tcp_edge) |
      select(.tcp_router.nsx_lbs.pool_name == $tcp_pool) |
      select(.tcp_router.nsx_lbs.security_group == $tcp_lb_sg) |
      select(.tcp_router.nsx_lbs.port == ($tcp_port | tonumber)) |
      select(.router.nsx_security_groups[0] == $router_sg) |
      select(.router.nsx_lbs.edge_name == $router_edge) |
      select(.router.nsx_lbs.pool_name == $router_pool) |
      select(.router.nsx_lbs.security_group == $router_lb_sg) |
      select(.router.nsx_lbs.port == ($router_port | tonumber)) |
      select(.diego_brain.nsx_security_groups[0] == $diego_sg) |
      select(.diego_brain.nsx_lbs.edge_name == $diego_edge) |
      select(.diego_brain.nsx_lbs.pool_name == $diego_pool) |
      select(.diego_brain.nsx_lbs.security_group == $diego_lb_sg) |
      select(.diego_brain.nsx_lbs.port == ($diego_port | tonumber))')

  exitcode=$?
  return $(Expect $exitcode ToBe 0)
)


# this spies on calls to om-linux checking for
# any flags matching `--product-properties`
# if found it will return the value for the flag
# which should be the iaas config json
function omLinuxSpy () {
  local printargval=false

  for i in "$@"; do
    if $printargval; then
      echo $i
      local printargval=false
    fi
    if [[ $i == "--product-resources" ]]; then
      local printargval=true
    fi

    if [[ $i == "/api/v0/certificates/generate" ]]; then
      echo "---- FAKE CERT ----"
    fi
  done
}

# loads up some defaults which need to be
# set in order for jq parsing to not throw
# errors
function helperLoadDefaultEnvVars () {
  set +u
  OPS_MGR_HOST=""
  OPS_MGR_USR=""
  OPS_MGR_PWD=""
  BACKUP_PREPARE_INSTANCES=1
  CCDB_INSTANCES=1
  CLOCK_GLOBAL_INSTANCES=1
  CLOUD_CONTROLLER_INSTANCES=1
  CLOUD_CONTROLLER_WORKER_INSTANCES=1
  CONSUL_SERVER_INSTANCES=1
  DIEGO_BRAIN_INSTANCES=1
  DIEGO_CELL_INSTANCES=1
  DIEGO_DATABASE_INSTANCES=1
  DOPPLER_INSTANCES=1
  ETCD_TLS_SERVER_INSTANCES=1
  HA_PROXY_INSTANCES=1
  LOGGREGATOR_TC_INSTANCES=1
  MYSQL_INSTANCES=1
  MYSQL_MONITOR_INSTANCES=1
  MYSQL_PROXY_INSTANCES=1
  NATS_INSTANCES=1
  NFS_SERVER_INSTANCES=1
  ROUTER_INSTANCES=1
  SYSLOG_ADAPTER_INSTANCES=1
  SYSLOG_SCHEDULER_INSTANCES=1
  TCP_ROUTER_INSTANCES=1
  UAA_INSTANCES=1
  UAADB_INSTANCES=1
}
