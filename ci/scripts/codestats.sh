#!/bin/bash -eux

echo "Code stats for $REPO_NAME"
STATSJSON=/tmp/codestats.json
cloc code-repo --json | tee $STATSJSON

python -c "
import json


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

print metrics

api.Metric.send(metrics)
"
