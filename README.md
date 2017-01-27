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
