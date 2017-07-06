#!/bin/bash

set -eu

fly -tlrp3 sp -p images -c ci/images/pipeline.yml \
  -l <(lpass show czero-github --notes) \
  -l <(lpass show czero-dockerhub --notes) \
  -l <(lpass show czero-aws --notes)
