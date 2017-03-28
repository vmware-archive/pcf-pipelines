#!/bin/bash -e

chmod +x om-cli/om-linux

CMD=./om-cli/om-linux

function fn_ert_balanced_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

ERT_AZS=$(fn_ert_balanced_azs $TILE_OTHER_AVAILABILITY_ZONES)

TILE_NETWORK=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$TILE_SINGLETON_AVAILABILITY_ZONE"
  },
  "other_availability_zones": [
    $ERT_AZS
  ],
  "network": {
    "name": "$TILE_NETWORK"
  }
}
EOF
)

TILE_PROPERTIES=$(cat <<-EOF
{
  ".windows_diego_cell.executor_disk_capacity": {
    "value": "$EXECUTOR_DISK_CAPACITY"
  },
  ".windows_diego_cell.executor_memory_capacity": {
    "value": "$EXECUTOR_MEMORY_CAPACITY"
  }
}
EOF
)

TILE_RESOURCES=$(cat <<-EOF
{
  "windows_diego_cell": {
    "instance_type": {"id": "automatic"},
    "instances" : $WINDOWS_CELL_COUNT
  }
}
EOF
)

$CMD --target https://$OPS_MGR_HOST --username $OPS_MGR_USR --password $OPS_MGR_PWD --skip-ssl-validation \
	configure-product --product-name "${PRODUCT_NAME}" \
	--product-properties "$TILE_PROPERTIES" \
	--product-network "$TILE_NETWORK" \
	--product-resources "$TILE_RESOURCES"
