# PCF Pipelines

**Please use the [Pivotal Network release](https://network.pivotal.io/products/pcf-automation/) of `pcf-pipelines` for stability. Using this repo directly may result in breaking the pipelines that consume it. Tracking master is considered unstable.**

This is a collection of [Concourse](https://concourse.ci) pipelines for
installing and upgrading [Pivotal Cloud Foundry](https://pivotal.io/platform).

Other pipelines which may be of interest are listed at the end of this README.

![Concourse Pipeline](install-pcf/gcp/embed.png)

### Install-PCF pipelines
Deploys PCF for whichever IaaS you choose. For public cloud installs, such as AWS, Azure, and GCP, the pipeline will deploy the necessary infrastructure in the public cloud, such as the networks, loadbalancers, and databases, and use these resources to then deploy PCF (Ops Manager and Elastic Runtime). On-premise private datacenter install pipelines, such as with vSphere and Openstack, do not provision any infrastructure resources and only deploy PCF, using resources that are specified in the parameters of the pipeline.

The desired output of these install pipelines is a PCF deployment that matches the [Pivotal reference architecture](http://docs.pivotal.io/pivotalcf/refarch), usually using three availability zones and opting for high-availability components whenever possible. If you want to deploy a different architecture, you may have to modify these pipelines to get your desired architecture.

These pipelines are found in the `install-pcf` directory, sorted by IaaS.


**Compatibility Matrix**

| IAAS | pipelines release | OM version | ERT version | 
| :--- | --- | --- | --- |
| vSphere | v0.18.0 | 1.12.x  | 1.12.3  |
| Azure | v0.18.0 | 1.12.x | 1.12.3  |
| AWS | v0.18.0 | 1.12.x | 1.12.3  |
| GCP | v0.18.0 | 1.12.x  | 1.12.3  |

*Note: Latest known version of ERT tested against pcf-pipelines
 
| IAAS | pipelines release | OM version | ERT version | 
| :--- | --- | --- | --- |
| vSphere | v0.17.0 | 1.11.12  | 1.11.8  |
| Azure | v0.17.0 | 1.11.12  | 1.11.8  |
| AWS | v0.17.0 | 1.11.12  | 1.11.8  |
| GCP | v0.17.0 | 1.11.12  | 1.11.8  |

*Note: ERT v1.11.14 is not compatible with pcf-pipelines

### Upgrade pipelines
Used to keep your PCF foundation up to date with the latest patch versions of PCF software from Pivotal Network. They can upgrade Ops Manager, Elastic Runtime, other tiles, and buildpacks. You will need one pipeline per tile in your foundation, to keep every tile up to date, and one pipeline to keep Ops Manager up to date.

These upgrade pipelines are intended to be kept running for as long as the foundation exists. They will be checking Pivotal Network periodically for new software versions, and apply these updates to the foundation. Currently, these pipelines are only intended for patch upgrades of PCF software (new --.--.n+1 versions), and are not generally recommended for minor/major upgrades (--.n+1.-- or n+1.--.-- versions). This is because new major/minor upgrades generally require careful reading of the release notes to understand what changes will be introduced with these releases before you commit to them, as well as additional configuration of the tiles/Ops Manager (these upgrade pipelines do not have any configure steps, by default).

These pipelines are found in any of the directories with the `upgrade-` prefix.

## Prerequisites

- [install a Concourse server](https://concourse.ci/installing.html)
- download the [Fly CLI](https://concourse.ci/fly-cli.html) to interact with the Concourse server
- depending on where you've installed Concourse, you may need to set up
[additional firewall rules](FIREWALL.md "Firewall") to allow Concourse to reach
third-party sources of pipeline dependencies

## Usage

1. Log in to [Pivotal Network](https://network.pivotal.io/products/pcf-automation) and download the latest version of PCF Platform Automation with Concourse (PCF Pipelines).

1. Each pipeline has an associated `params.yml` file. Edit the `params.yml` with details related to your infrastructure.

1. Log in and target your Concourse:
   ```
   fly -t yourtarget login --concourse-url https://yourtarget.example.com
   ```

1. Set your pipeline with the `params.yml` file you created in step two above. For example:
   ```
   fly -t yourtarget set-pipeline \
     --pipeline upgrade-opsman \
     --config upgrade-ops-manager/aws/pipeline.yml \
     --load-vars-from upgrade-ops-manager/aws/params.yml
   ```

1. Navigate to the pipeline url, and unpause the pipeline.

1. Depending on the pipeline, the first job will either trigger on its own or the job will require manual intervention. Some pipelines may also require manual work during the duration of the run to complete the pipeline.

## Upgrading/Extending

It's possible to modify `pcf-pipelines` to suit your particular needs using
[`yaml-patch`](https://github.com/krishicks/yaml-patch) (disclaimer: this tool is still in its early prototyping phase). We'll show you how to
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

## Deploying and Managing Multiple Pipelines

There is an experimental tool which you may find helpful for deploying and managing multiple customized pipelines all at once, called [PCF Pipelines Maestro](https://github.com/pivotalservices/pcf-pipelines-maestro). It uses a single pipeline to generate multiple pipelines for as many PCF foundations as you need.

## Pipeline Compatibility Across PCF Versions

Our goal is to at least support the latest version of PCF with these pipelines. Currently there is no assurance of backwards compatibility, however we do keep past releases of the pipelines to ensure there is at least one version of the pipelines that would work with an older version of PCF.

Compatbility is generally only an issue whenever Pivotal releases a new version of PCF software that requires additional configuration in Ops Manager. These new required fields then need to be either manually configured outside the pipeline, or supplied via a new configuration added to the pipeline itself.

## Pipelines for Airgapped Environments

The pipelines cannot be used as-is in environments that have no outbound access to the Internet as the pipelines expect to be able to pull resources from the Internet, including from Pivotal Network and Dockerhub. Various aspects of the pipelines need to be modified to be suitable for use in airgapped environments.

### Resources

All resources must be provided from within the airgapped environment. The pipelines and their tasks don't care _where_ the resources come from, just that they contain the same bits that they would have gotten from the original resource. For resources that come from Pivnet this means including the metadata.json file that pivnet-resource normally downloads as some tasks use that file to determine dependencies of the resource, such as what stemcell a tile requires.

### Tasks

In rare cases a task will attempt to reach the Internet. An example of this is the Install PCF pipelines that reach out to Pivnet to get the appropriate stemcell for the PCF Elastic Runtime version that was pulled by Concourse. Any such task needs to be modified/replaced to support pulling those artifacts from within the airgapped environment.

Additionally, tasks also define an `image_resource` for the source of the rootfs Concourse will use when executing the task. This rootfs typically is specified as a `docker-image` resource residing in Dockerhub. This `image_resource` resource must also be supplied from within the airgapped environment.

### Implementation

Given Concourse ships with the [s3-resource](https://github.com/concourse/s3-resource), and there are many S3-compatible blobstores that can be used from within airgapped environments such as [Minio](https://minio.io/) and [Dell EMC Elastic Cloud Storage](https://www.dellemc.com/en-us/storage/ecs/index.htm), our chosen implementation is to use S3 for supplying all of the required resources.

We've created two pipelines, `create-offline-pinned-pipelines` and `unpack-pcf-pipelines-combined`, that are meant to be used to facilitate physical transfer of artifacts to the airgapped environment.

`create-offline-pinned-pipelines` is used to:

* Pull all required resources from their normal locations on the Internet
* Create a tarball for each resource containing the entire contents of the resource
* Flatten the tasks for the pipelines into the pipeline definitions
* Replace all of the `resource` and `image_resource` definitions with resources of type `s3`
* Hardcode the `get` of all resources and the `image_resource` definitions to the specific version of each resource that was downloaded
* Create a GPG-encrypted tarball with each resource tarball created above and a `shasum` manifest of each resource tarball
* Put the tarball to a location within S3 storage that can be downloaded manually and put on physical media for transfer to the airgapped environment

`unpack-pcf-pipelines-combined` is used to:

* Download, decrypt, and extract the GPG-encrypted tarball into its components after it has been manually copied to the `pcf-pipelines-combined/` path in S3
* Verify the `shasum` manifest of the tarball contents
* Put the tarball parts into their appropriate locations within the airgapped S3 storage for use by the pipelines

From this point the `pcf-pipelines` folder in the configured S3 bucket in the airgapped environment contains the pcf-pipelines tarball that can then be used to set a pipeline within.

### Requirements

* The online environment must have access to Dockerhub and Pivnet
* Concourse 3.3.3+ in both online and airgapped environments

#### Bootstrapping

For the `unpack-pcf-pipelines-combined` to work there must be a single manual transfer of the czero-cflinuxfs2 tarball to the czero-cflinuxfs2 folder within the airgapped environment's S3 storage. Only after that is done can the `unpack-pcf-pipelines-combined` pipeline be set and unpaused.

## Contributing

### Pipelines and Tasks

For practicalities, please see our [Contributing](https://github.com/pivotal-cf/pcf-pipelines/blob/master/CONTRIBUTING.md) page for more information.

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

#### Other notable examples of pipelines for PCF

[PCFS Sample Pipelines](https://github.com/pivotalservices/concourse-pipeline-samples) - includes pipelines for
- integrating Artifactory, Azure blobstores, GCP storage, or Docker registries
- blue-green deployment of apps to PCF
- backing up PCF
- deploying Concourse itself with bosh.
- and more...
