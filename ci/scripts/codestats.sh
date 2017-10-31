#!/bin/bash -eu

echo "Code stats for $REPO_NAME"
STATSJSON=/tmp/codestats.json
cloc code-repo --json | tee $STATSJSON

python -c "
import os
import json
import yaml

from datadog import initialize, api

options = {
    'api_key': '$DATADOG_API_KEY',
    'app_key': '$DATADOG_APP_KEY'
}

initialize(**options)

stats = json.load(open('$STATSJSON'))

del stats['header']

metrics = []

metric_name = 'codestat.$REPO_NAME'
for lang in stats:
  if lang == 'SUM':
    continue
  for attr in stats[lang]:
    count = stats[lang].get(attr)
    metrics.append({'metric': metric_name, 'points': count, 'tags': [lang, attr], 'host': 'ci'})

pipelines_count = 0

for dir, subdirs, files in os.walk('code-repo'):
  if 'pipeline.yml' in files:
    pipelines_count +=1
    try:
      params_file = open(os.path.join(dir, 'params.yml'))
      params = yaml.load(params_file)

      pipeline_name = dir[10:]  # strip 'code-repo/'
      metrics.append({'metric': metric_name + '.' + pipeline_name, 'points': len(params), 'tags': ['params'], 'host': 'ci'})
    except Exception, e:
      print e

metrics.append({'metric': metric_name + '.pipelines_total', 'points': pipelines_count, 'tags': [], 'host': 'ci'})

api.Metric.send(metrics)
"
