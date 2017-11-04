#!/usr/bin/env python2

import os
import json
import yaml

import subprocess
from datadog import initialize, api

options = {
    'api_key': os.environ['DATADOG_API_KEY'],
    'app_key': os.environ['DATADOG_APP_KEY'],
}

initialize(**options)

repo_name = os.environ["REPO_NAME"]
print "Code stats for " + repo_name
cloc_output = subprocess.check_output("cloc code-repo --json", shell=True)

stats = json.loads(cloc_output)

del stats['header']

metrics = []

metric_name = 'codestat.' + repo_name
for lang in stats:
  if lang == 'SUM':
    continue
  for attr in stats[lang]:
    count = stats[lang].get(attr)
    metrics.append({'metric': metric_name, 'points': count, 'tags': [lang, attr], 'host': 'ci'})

pipelines_count = 0

total_params = {}
for dir, subdirs, files in os.walk('code-repo'):
  if 'pipeline.yml' in files:
    pipelines_count +=1
    try:
      params_file = open(os.path.join(dir, 'params.yml'))
      params = yaml.load(params_file)
      total_params.update(params)

      pipeline_name = dir[10:]  # strip 'code-repo/'
      metrics.append({'metric': metric_name + '.' + pipeline_name, 'points': len(params), 'tags': ['params'], 'host': 'ci'})
    except Exception, e:
      print e

metrics.append({'metric': metric_name + '.pipelines_total', 'points': pipelines_count, 'tags': [], 'host': 'ci'})
metrics.append({'metric': metric_name + '.params_total', 'points': len(total_params), 'tags': [], 'host': 'ci'})

api.Metric.send(metrics)

print "Total Pipelines: %i / Total params %i" % (pipelines_count, len(total_params))
