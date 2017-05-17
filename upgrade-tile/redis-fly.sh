#!/usr/bin/env bash

set -e -x

fly -t ci login -u concourse -p changeme -c http://10.193.65.102:8080/

fly -t ci set-pipeline --pipeline upgrade-redis --config pipeline.yml --load-vars-from redis.yml
fly -t ci unpause-pipeline --pipeline upgrade-redis
