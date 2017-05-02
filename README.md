# PCF Pipelines

This is a collection of [Concourse](https://concourse.ci) pipelines for
installing and upgrading [Pivotal Cloud Foundry](https://pivotal.io/platform).

## Usage

You'll need to [install a Concourse server](https://concourse.ci/installing.html)
and get the [Fly CLI](https://concourse.ci/fly-cli.html)
to interact with that server.

Depending on where you've installed Concourse, you may need to set up
[additional firewall rules](FIREWALL.md "Firewall") to allow Concourse to reach
third-party sources of pipeline dependencies.

Each pipeline has an associated `params.yml` file next to it that you'll need to fill out with the appropriate values for that pipeline.

After filling out your params.yml, set the pipeline:

```
fly -t yourtarget login --concourse-url https://yourtarget.example.com
fly -t yourtarget set-pipeline \
  --pipeline upgrade-opsman \
  --config upgrade-ops-manager/aws/pipeline.yml \
  --load-vars-from upgrade-ops-manager/aws/params.yml
```

## Upgrading/Extending

It's possible to modify `pcf-pipelines` to suit your particular needs using
[`yaml-patch`](https://github.com/krishicks/yaml-patch). We'll show how to
replace the `pivnet-opsmgr` resource in the AWS Upgrade Ops Manager pipeline
(`upgrade-ops-manager/aws/pipeline.yml`) as an example below.

This example assumes you're either using AWS S3 or running your own
S3-compatible store and plan to download the files from Pivotal Network (Pivnet)
manually, putting them in your S3-compatible store, with a naming format like
**ops-mgr-v1.10.0**.

First, create an ops file that has the configuration of the new resource (read
more about resources [here](https://concourse.ci/concepts.html#section_resources)).
We'll also remove the `resource_types` section of the pipeline as the
pivnet-opsmgr resource is the only pivnet resource in the pipeline:

```
cat > use-s3-opsmgr.yml <<EOF
- op: replace
  path: /resources/name=pivnet-opsmgr
  value:
    name: pivnet-opsmgr
    type: s3
    source:
      bucket: pivnet-releases
      regexp: ops-mgr-v([\d\.]+)

- op: remove
  path: /resource_types
EOF
```

_Note: We use the same `pivnet-opsmgr` name so that the rest of the pipeline, which does `gets` on the resource by that name, continues working._

Next, use `yaml-patch` to replace the current pivnet-opsmgr resource with your
own:

_Note: Because Concourse presently uses curly braces for `{{placeholders}}`, we
need to wrap those placeholders in quotes to make them strings prior to parsing
the YAML, and then unwrap the quotes after modifying the YAML. Yeah, sorry._

```
sed -e "s/{{/'{{/g" -e "s/}}/}}'/g" pcf-pipelines/upgrade-ops-manager/aws/pipeline.yml |
yaml-patch -o use-s3-opsmgr.yml |
sed -e "s/'{{/{{/g" -e "s/}}'/}}/g" > upgrade-opsmgr-with-s3.yml
```

Now your pipeline has your new s3 resource in place of the pivnet resource from before.

You can add as many operations as you like, chaining them with successive `-o` flags to `yaml-patch`.

See [operations](operations) for more examples of operations.

## Contributing

### Pipelines and Tasks

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

#### Pipelines

Pipelines should define jobs that encapsulate conceptual chunks of work, which
is then split up into tasks within the job. Jobs should use `aggregate` where
possible to speed up actions like getting resources that the job requires.

Pipelines should not declare task YAML inline; they should all exist within a
directory under `tasks/`.

#### Tasks

Each task has a `task.yml` and a `task.sh` file. The task YAML has an internal
reference to its `task.sh`.

Tasks declare what their inputs and outputs are. These inputs and outputs
should be declared in a generic way so they can be used by multiple pipelines.

Tasks should not use `wget` or `curl` to retrieve resources; doing so means the
resource cannot be cached, cannot be pinned to a particular version, and cannot
be supplied by alternative means for airgapped environments.

#### Running tests

There are a series of tests that should be run before creating a PR or pushing
new code. Run them with ginkgo:

```
go get github.com/onsi/ginkgo/ginkgo
go get github.com/onsi/gomega
go get github.com/concourse/atc

ginkgo -r -p
```
