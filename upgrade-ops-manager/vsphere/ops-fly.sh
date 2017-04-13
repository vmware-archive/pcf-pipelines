#!/usr/bin/env bash

set -e -x

fly -t ci login -u concourse -p changeme -c http://10.193.65.102:8080/

fly -t ci set-pipeline --pipeline upgrade-ops-manager --config pipeline.yml --load-vars-from .params.yml
fly -t ci unpause-pipeline --pipeline upgrade-ops-manager
