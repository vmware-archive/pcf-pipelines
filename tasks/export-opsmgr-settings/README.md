# Export Ops Manager settings
1. Make sure that params.yml contains required vSphere and Ops Manager settings.  At least 8G of memory should be allocated.
2. Create folders containing required inputs - pcf-pipelines and [tool-om](https://github.com/c0-ops/om/releases), and output folder - opsmgr-settings.
3. To setup the pipeline run:
>fly -t lite set-pipeline -p upgrade-opsmgr -c ./pcf-pipelines/upgrade-opsmgr/pipeline.yml -l params.yml
4. To exectute the pipeline run:
>fly -t lite execute -c ./pcf-pipelines/tasks/export-opsmgr-settings/task.yml -i pcf-pipelines=./pcf-pipelines/ -i tool-om=./tool-om/
