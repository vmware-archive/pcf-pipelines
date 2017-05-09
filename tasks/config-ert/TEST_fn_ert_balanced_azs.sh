#!/bin/bash -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $SCRIPT_DIR/fn_ert_balanced_azs.sh

DEPLOYMENT_NW_AZS=az1,az2,az3
ERT_AZS=$(fn_ert_balanced_azs "${DEPLOYMENT_NW_AZS}")

echo $ERT_AZS 

DEPLOYMENT_NW_AZS="az1 with space,az2 with space,az3 with space"

ERT_AZS=$(fn_ert_balanced_azs "${DEPLOYMENT_NW_AZS}")

echo $ERT_AZS