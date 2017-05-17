#!/usr/bin/env bash

set -e -x

fly -t lite login -u concourse -p changeme -c http://104.154.86.251:8080

fly -t lite set-pipeline --pipeline upgrade-ops-manager-gcp --config pipeline.yml --load-vars-from .params.yml
fly -t lite unpause-pipeline --pipeline upgrade-ops-manager-gcp