# PCF Pipelines

This is a collection of pipelines for installing and upgrading Pivotal Cloud Foundry.

## Pipelines and Tasks

The pipelines and tasks in this repo follow a simple pattern which must be adhered to:

```
.
├── some-pipeline
|   ├── params.yml
|   └── pipeline.yml
└── tasks
    ├── a-task
    │   ├── task.sh
    │   └── task.yml
    └── another-task
        ├── task.sh
        └── task.yml
```

Each pipeline has a `pipeline.yml`, which contains the YAML for a single
Concourse pipeline. Pipelines typically require parameters, either for resource
names or for credentials, which are supplied externally via `{{placeholders}}`.

A pipeline may have a `params.yml` file which is a template for the parameters
that the pipeline requires. This template should have placeholder values,
typically CHANGEME, or defaults where appropriate. This file should be filled
out and stored elsewhere, such as in LastPass, and then supplied to `fly` via
the `-l` flag. See the
[fly documentation](http://concourse.ci/fly-set-pipeline.html) for more.

### Pipelines

Pipelines should define jobs that encapsulate conceptual chunks of work, which
is then split up into tasks within the job. Jobs should use `aggregate` where
possible to speed up actions like getting resources that the job requires.

Pipelines should not declare task YAML inline; they should all exist within a
directory under `tasks/`.

### Tasks

Each task has a `task.yml` and a `task.sh` file. The task YAML has an internal
reference to its `task.sh`.

Tasks declare what their inputs and outputs are. These inputs and outputs
should be declared in a generic way so they can be used by multiple pipelines.

Tasks should not use `wget` or `curl` to retrieve resources; doing so means the
resource cannot be cached, cannot be pinned to a particular version, and cannot
be supplied by alternative means for airgapped environments.

---

## Firewall rules: [here](FIREWALL.md "Firewall")

---

# Offline configurations

This segment details several possible offline configurations for resources leveraged in our reference pipelines

## Github Release Resource (using github enterprise)
**switch to using an internal github enterprise**

Steps:
- clone the public release
- create a repo on your enterprise github
- add enterprise github as a new remote
- push public repo to enterprise github remote
	- (https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes)
- add github_api_url values to pipeline yaml and params yaml

```
#sample yaml snippet
- name: my-release-binary 
  type: github-release
  source:
    user: pivotal-cf
    repository: om
    access_token: {{github_enterprise_token}}
    github_api_url: {{github_enterprise_url}}

```

---


## Github Release Resource or Pivnet resource (using s3)
**switch to using an internal/external s3 compatible store**

Pre-Reqs:
- access to an s3 compatible store

Steps:
- setup a versioned s3 bucket (each resource should have its own bucket)
- download asset from github release page or pivotal network
- upload asset into bucket 
  - make sure the filename matches what was in the github release or change the rest of the pipeline to match
- replace github-release resource with s3 resource in pipeline yaml (as shown below)

```
#sample yaml snippet
- name: my-release-binary
  type: s3
  source: 
    bucket: releases
    regexp: {{s3_filepath}}
    access_key_id: {{s3_access_key}}
    secret_access_key: {{s3_secret}}
    region_name: {{s3_region}}
    endpoint: {{s3_endpoint}}
```

---

## Git resource (using a local git)
- clone or fork repository to a local git server
- modify all git resources in yaml with your local git uri(s)

``` 
#sample yaml snippet
- name: pcf-pipelines
  type: git
  source:
    uri: git@mylocalgit.company.com:pivotal-cf/pcf-pipelines
    branch: master
```

---

## Docker Images (using private registry)
**switch to using a non-docker hub enabled setup for offline**

Pre-Reqs:
- local docker registry
  - for a way to deploy a BOSH managed docker registry see:
    (https://github.com/enaml-ops/omg-product-bundle/tree/master/products/dockerregistry)

Steps:
- docker pull from docker hub or desired rootfs source
- docker push to local docker registry
- add full local url to docker container repo in pipeline yaml

```
#sample yaml snippet

# this example is for a pipeline docker resource
resource_types:
- name: pivnet
  type: docker-image
  source:
    repository: myregistrydomain.com:5000/pivotalcf/pivnet-resource
    tag: latest-final

# or

# this example is for a task.yml
image_resource:
  type: docker-image
  source:
    repository: my.local.registry:8080/my/image
    insecure_registries: ["my.local.registry:8080"]
    username: myuser
    password: mypass
    email: x@x.com
```

---

## Docker Images (using git)
**switch to using a non docker hub enabled setup without a private docker
repository**
**this is for running tasks in the absence of dockerhub access (this is not for use w/ resources only task base images)**

Pre-Reqs:
- Git

Steps:
- obtain RootFS using `docker archive` for the docker image cloudfoundry/cflinuxfs2
- store your rootfs in git 
- create git repo with archive tgz in it
- configure tasks to pull rootfs from git using the `image` element instead of `image_resource`.
  - docs: 
    - (https://concourse.ci/task-step.html#task-image)
    - (https://concourse.ci/running-tasks.html#task-config-image)

```
# sample yaml snippet
resources:
- name: my-project
  type: git
  source: {uri: https://github.com/my-user/my-project}

jobs:
- name: use-task-image
  plan:
  - get: my-project
  - task: use-task-image
    image: my-project/my-rootfs.tgz 
    file: my-project/ci/tasks/my-task.yml
```
