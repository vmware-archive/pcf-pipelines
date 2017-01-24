# PCF Pipelines

This is a collection of pipelines for installing and upgrading Pivotal Cloud Foundry.

Some pipelines will have params files for storing secrets, `params.yml`. The
params file may have CHANGEME as their value that you will need to change
before using the params file.

After changing any CHANGEME values, set a pipeline with the params file as such:

```
fly -t your-concourse login
fly -t your-concourse set-pipeline upgrade-ert -c upgrade-ert/pipeline.yml -l upgrade-ert/params.yml
```
