# Examples of yaml-patch usage patterns for pcf-pipelines

### Index

- [Add a task to a job](#add-task-to-job)
- [Add a task to a job after a specific task](#add-task-to-job-after-another-task)
- [Replace a resource definition in the pipeline YML](#replace-resource-definition)
- [Add email notifications to an existing pipeline](#add-email-nofitications)
- [Change the trigger flag of a job resource](#change-trigger-flag)
- [Additional operations samples](#additional-operations-samples)

---

### <a name="add-task-to-job"></a> Add a task to a job

1. Source YAML: `job.yml`  
```  
---  
jobs:  
- name: my-job  
  plan:  
  - get: my-resource  
  - task: first-task  
    file: task1.yml  
  - task: second-task  
    file: task2.yml    
```  
2. Operations file: `add-task.yml`  
```  
- op: add  
  path: /jobs/name=my-job/plan/-  
  value:  
    task: third-task  
    file: task3.yml  
```  
3. Execute yaml-patch command  
   `cat job.yml | yaml-patch -o add-task.yml > result.yml`    

4. Resulting patched file: `result.yml`  
```  
---  
jobs:  
- name: my-job  
  plan:  
  - get: my-resource  
  - task: first-task  
    file: task1.yml  
  - task: second-task  
    file: task2.yml  
  - task: third-task  
    file: task3.yml      
```  


---

### <a name="add-task-to-job-after-another-task"></a> Add a task to a job after a specific task

The combined use of the `replace` operation from `yaml-patch` with the `do` tasks/resources grouping in Concourse pipelines allows you to "insert" tasks into the middle of the tasks of a job.

1. Source YAML: `job-insert-task.yml`  
```  
---  
jobs:  
- name: my-job  
  plan:  
  - get: my-resource  
  - task: first-task  
    file: task1.yml  
  - task: last-task  
    file: taskn.yml    
```  
2. Operations file: `insert-task.yml`  
```  
- op: replace  
  path: /jobs/name=my-job/plan/task=first-task   
  value:  
    do:  
    - task: first-task  
      file: task1.yml  
    - task: second-task   
      file: task2.yml  
```  
3. Execute yaml-patch command  
   `cat job-insert-task.yml | yaml-patch -o insert-task.yml  > result.yml`    

4. Resulting patched file: `result.yml`  
```  
---  
jobs:  
- name: my-job  
  plan:  
  - get: my-resource  
  do:  
    - task: first-task  
      file: task1.yml  
    - task: second-task   
      file: task2.yml   
  - task: last-task   
    file: taskn.yml        
```  


---


### <a name="replace-resource-definition"> Replace a resource definition in the pipeline YML

The example below is similar to the resource replacement action done by pcf-pipelines in operations file [use-pivnet-release.yml](https://github.com/pivotal-cf/pcf-pipelines/tree/master/operations/use-pivnet-release.yml) to use the pipelines release from PivNet instead of GitHub. When the resource name is updated, all the tasks that reference that name also need to be updated accordingly.    

1. Source YAML: `resource-entry.yml`  
```  
---  
resources:  
- name: pcf-pipelines  
  type: git  
  source:  
    uri: git@github.com:pivotal-cf/pcf-pipelines.git  
    branch: master  
    private_key: ((git_private_key))  
```  
2. Operations file: `replace-resource.yml`  
```  
---  
- op: replace  
  path: /resources/name=pcf-pipelines  
  value:  
    name: pcf-pipelines
    type: pivnet  
    source:  
      api_token: "((pivnet_token))"  
      product_slug: pcf-automation  
      product_version: ~  
```  
3. Execute yaml-patch command  
   `cat resource-entry.yml | yaml-patch -o replace-resource.yml > result.yml`    

4. Resulting patched file: `result.yml`  
```  
---   
resources:  
- name: pcf-pipelines
  type: pivnet  
  source:  
    api_token: "((pivnet_token))"  
    product_slug: pcf-automation  
    product_version: ~    
```  


---


### <a name="add-email-nofitications"> Add email notification to an existing pipeline

For a sample on how to add email notification to all jobs of a pipeline (e.g. for [upgrade-tile.yml](https://github.com/pivotal-cf/pcf-pipelines/blob/master/upgrade-tile/pipeline.yml)), see  [add-email-nofication-to-upgrade-tile.yml](https://github.com/pivotal-cf/pcf-pipelines/blob/master/operations/add-email-nofication-to-upgrade-tile.yml).

The operations file injects entries to `resource_types` and `resources` arrays for the email resource and then adds email notification actions for *success* and *failure* scenarios to the pipeline jobs.

1. Source YAML:  [upgrade-tile.yml](https://github.com/pivotal-cf/pcf-pipelines/blob/master/upgrade-tile/pipeline.yml)  

2. Operations file:  [add-email-nofication-to-upgrade-tile.yml](https://github.com/pivotal-cf/pcf-pipelines/blob/master/operations/add-email-nofication-to-upgrade-tile.yml)  

3. Execute yaml-patch command  
   `cat upgrade-tile.yml | yaml-patch -o add-email-nofication-to-upgrade-tile.yml > upgrade-tile-with-notifications.yml`    

4. Resulting patched file: `upgrade-tile-with-notifications.yml`  


---


### <a name="change-trigger-flag"> Change the Trigger flag of a job resource

For a sample on how to update the *Trigger* parameter for the `apply-changes` job of the [upgrade-tile.yml](https://github.com/pivotal-cf/pcf-pipelines/blob/master/upgrade-tile/pipeline.yml#L103) pipeline, see sample [gated-apply-changes-job.yml](https://github.com/pivotal-cf/pcf-pipelines/blob/master/operations/gated-apply-changes-job.yml).

1. Source YAML: `job-trigger.yml`  
```  
---  
jobs:  
- name: my-job  
  plan:  
  - get: my-resource  
    trigger: true
  - get: her-resource  
    trigger: true
  - task: first-task  
    file: task1.yml  
```  
2. Operations file: `replace-trigger.yml`  
```  
- op: replace
  path: /jobs/name=my-job/plan/get=my-resource/trigger
  value: false
```  
3. Execute yaml-patch command  
   `cat job-trigger.yml | yaml-patch -o replace-trigger.yml > result.yml`    

4. Resulting patched file: `result.yml`  
```  
---  
jobs:  
- name: my-job  
  plan:  
  - get: my-resource  
    trigger: false
  - get: her-resource  
    trigger: true
  - task: first-task  
    file: task1.yml  
```  

---


### <a name="additional-operations-samples"> Additional operations samples

See [operations](https://github.com/pivotal-cf/pcf-pipelines/tree/master/operations) for more examples of yaml-patch operations.

- [Use Artifactory as the source for the Upgrade ERT pipeline resource](https://github.com/pivotal-cf/pcf-pipelines/tree/master/operations/upgrade-ert-use-artifactory.yml)
- [Use Artifactory as the source for the Upgrade Tile pipeline resource](https://github.com/pivotal-cf/pcf-pipelines/tree/master/operations/upgrade-tile-use-artifactory.yml)
