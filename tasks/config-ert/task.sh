#!/bin/bash

set -eu
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $script_dir/configure_product.sh
configure_product
