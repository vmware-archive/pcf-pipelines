# Install PCF on GCP 

- compatible with PCF 1.9

#### This process describes how to get the pipeline and install a PCF on a properly configured GCP
http://docs.pivotal.io/pivotalcf/1-10/refarch/gcp/gcp_ref_arch.html

```bash

# to get the pipeline bits
# download from pivnet 

# go to the pipeline dir
$ cd pcf-pipelines/install-pcf/gcp 

# check the readme for pre-reqs and guidance
$ cat README.md

# fill in your environments specific values
$ vim params.yml

# send your pipeline to a concourse (targeting and logging in info can be found here: https://concourse.ci/fly-cli.html)
$ fly -t lite set-pipeline -p deploy-pcf -c pipeline.yml -l params.yml

# unpause your pipeline
$ fly -t lite unpause-pipeline -p deploy-pcf

```
# PCF on GCP

![Concourse Pipeline](embed.png)

This pipeline uses Terraform to create all the infrastructure required to run a
3 AZ PCF deployment on GCP.

## Usage

This pipeline downloads artifacts from DockerHub, GitHub, and the configured
S3-compatible object store, and as such the Concourse instance must have access
to those. You can use AWS S3 as your S3-compatible object store, but note that
Terraform outputs a .tfstate file that contains plaintext secrets. For this
reason Minio is preferrable to keep the visibility of the .tfstate local to
Concourse. (See instructions below for how to run Minio in a Docker container.)

1. Within Google Cloud Platform, enable the following:
  * GCP Compute API [here](https://console.cloud.google.com/apis/api/compute_component)
  * GCP Storage API [here](https://console.cloud.google.com/apis/api/storage_component)
  * GCP SQL API [here](https://console.cloud.google.com/apis/api/sql_component)
  * GCP DNS API [here](https://console.cloud.google.com/apis/api/dns)
  * GCP Cloud Resource Manager API [here](https://console.cloud.google.com/apis/api/cloudresourcemanager.googleapis.com/overview)

2. Change all of the CHANGEME values in params.yml with real values
3. [Set the pipeline](http://concourse.ci/single-page.html#fly-set-pipeline), using your updated params.yml:
  ```
  fly -t lite set-pipeline -p deploy-pcf -c pipeline.yml -l params.yml
  ```

4. Unpause the pipeline if you haven't already. `upload-opsman-image` will automatically upload the latest matching version of Operations Manager

5. Trigger the `create-infrastructure` job. `create-infrastructure` will output at the end the DNS settings that you must configure before continuing.
6. Once DNS is set up you can run `configure-director`. From there the pipeline should automatically run through to the end.

### Tearing down the environment

There is a job, `wipe-env`, which you can run to destroy the infrastructure
that was created by `create-infrastructure`. If you want to bring the
environment up again, run `create-infrastructure`. This can also be used if
`create-infrastructure` fails for some reason, where Terraform creates only some
of the infrastructure.

### Getting Concourse

The easiest way to get started with Concourse is to use the [Vagrant Virtualbox
image](http://concourse.ci/single-page.html#vagrant).

```
vagrant init concourse/lite
vagrant up
fly -t lite login -c http://192.168.100.4:8080
```

### Getting an S3-compatible store

If you want to use Minio as your S3-compatible object store:

OSX:

```
docker run -e MINIO_ACCESS_KEY="example-access-key" \
           -e MINIO_SECRET_KEY="example-secret-key" \
           minio/minio server /tmp
```

Linux:

```
docker run -e MINIO_ACCESS_KEY="example-access-key" \
           -e MINIO_SECRET_KEY="example-secret-key" \
           --detach \
           --network host \
           minio/minio server /tmp
```

