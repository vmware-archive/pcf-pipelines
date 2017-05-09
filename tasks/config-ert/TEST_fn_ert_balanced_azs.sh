#!/bin/bash -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $SCRIPT_DIR/fn_ert_balanced_azs.sh

DEPLOYMENT_NW_AZS=az1,az2,az3
ERT_AZS=$(fn_ert_balanced_azs "${DEPLOYMENT_NW_AZS}")

if [[ $ERT_AZS != '[{"name":"az1"},{"name":"az2"},{"name":"az3"}]' ]]; 
then
    echo "Not expected: " $ERT_AZS
    exit 1
fi

DEPLOYMENT_NW_AZS="az1 with space,az2 with space,az3 with space"

ERT_AZS=$(fn_ert_balanced_azs "${DEPLOYMENT_NW_AZS}")

if [[ $ERT_AZS != '[{"name":"az1 with space"},{"name":"az2 with space"},{"name":"az3 with space"}]' ]]; 
then
    echo "Not expected: " $ERT_AZS
    exit 1
fi

