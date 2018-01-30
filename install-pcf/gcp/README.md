# PCF on GCP

![Concourse Pipeline](embed.png)

This pipeline uses Terraform to create all the infrastructure required to run a
3 AZ PCF deployment on GCP per the Customer[0] [reference
architecture](http://docs.pivotal.io/pivotalcf/refarch/gcp/gcp_ref_arch.html).

## Usage

This pipeline downloads artifacts from DockerHub (czero/rootfs and custom
docker-image resources) and the configured Google Cloud Storage bucket
(terraform.tfstate file), and as such the Concourse instance must have access
to those. Note that Terraform outputs a .tfstate file that contains plaintext
secrets.

1. Within Google Cloud Platform, enable the following:
  * GCP Compute API [here](https://console.cloud.google.com/apis/api/compute_component)
  * GCP Storage API [here](https://console.cloud.google.com/apis/api/storage_component)
  * GCP SQL API [here](https://console.cloud.google.com/apis/api/sql_component)
  * GCP DNS API [here](https://console.cloud.google.com/apis/api/dns)
  * GCP Cloud Resource Manager API [here](https://console.cloud.google.com/apis/api/cloudresourcemanager.googleapis.com/overview)
  * GCP Storage Interopability [here](https://console.cloud.google.com/storage/settings)

2. Create a bucket in Google Cloud Storage to hold the Terraform state file, enabling versioning for this bucket via:
  * the `gsutil` CLI: `gcloud auth activate-service-account --key-file credentials.json && gsutil versioning set on gs://<your-bucket>`
  * If you already have a service account and sufficient permissions, you can run `gcloud auth login` and `gsutil versioning set on gs://<your-bucket>`

3. Change all of the CHANGEME values in params.yml with real values. For the gcp_service_account_key, create a new service account key that has the following IAM roles. (See the Troubleshooting issue below to ensure you have indented this parameter correctly):
  * Cloud SQL Admin
  * Compute Instance Admin (v1)
  * Compute Network Admin
  * Compute Security Admin
  * DNS Administrator
  * Storage Admin

4. [Set the pipeline](http://concourse.ci/single-page.html#fly-set-pipeline), using your updated params.yml:
  ```
  fly -t lite set-pipeline -p deploy-pcf -c pipeline.yml -l params.yml
  ```

5. Unpause the pipeline
6. Run `bootstrap-terraform-state` job manually. This will prepare the s3 resource that holds the terraform state. This only needs to be run once.
7. `upload-opsman-image` will automatically upload the latest matching version of Operations Manager
8. Trigger the `create-infrastructure` job. `create-infrastructure` will output at the end the DNS settings that you must configure before continuing.
9. Once DNS is set up you can run `configure-director`. From there the pipeline should automatically run through to the end.

### Tearing down the environment

There is a job, `wipe-env`, which you can run to destroy the infrastructure
that was created by `create-infrastructure`.

_**Note: This job currently is not all-encompassing. If you have deployed ERT you will want to delete ERT from within Ops Manager before proceeding with `wipe-env`, as well as deleting the BOSH director VM from within GCP. This will be done automatically in the future.**_

If you want to bring the environment up again, run `create-infrastructure`.

## Known Issues

### `create-infrastructure` job trying to delete SSL cert in use

When the `create-infrastructure` job runs, it may generate an error like this:
`google_compute_ssl_certificate.ssl-cert (destroy): 1 error(s) occurred:
google_compute_ssl_certificate.ssl-cert: Error deleting ssl certificate: googleapi: Error 400: The ssl_certificate resource 'projects/<redacted>/global/sslCertificates/<redacted>-gcp-lb-cert' is already being used by 'projects/<redacted>/global/targetHttpsProxies/<redacted>-gcp-https-proxy', resourceInUseByAnotherResource`
When this happens, after you've initially run create-infrastructure, update your params to supply the generated certs so they aren't recreated. Note that you may need to use `|-` when entering the cert/key into your `params.yml`. 

### `wipe-env` job
* The job does not account for installed tiles, which means VMs created by tile
  installations will be left behind and/or prevent wipe-env from completing.
  Delete the tiles manually prior to running `wipe-env` as a workaround.
* The job does not account for the BOSH director VM, which will prevent the job
  from completing. Delete the director VM manually in the GCP console as a
  workaround.

### Allow SSH to Ops Manager without a Jumpbox
* There is presently no jumpbox installed as part of the Terraform scripts. If
  you need to SSH onto the Ops Manager VM add the `allow-ssh` tag to the network
  access tags for that vm. You'll need to add an SSH key to the instance, unless
  you are using the `gcloud` cli which will add it for you.

### Cloud SQL Authorized Networks

There is a set of authorized networks added for the Cloud SQL instance which
has been modified to include 0.0.0.0/0. This is due to Cloud SQL only
managing access through public networks. We don't have a good way to keep
updated with Google Compute Engine CIDRs, and the Google Cloud Proxy is not
yet available on BOSH-deployed VMs. Thus, to allow Elastic Runtime access to
Cloud SQL, we allow 0.0.0.0/0. When a better solution comes around we'll be
able to remove it and allow only the other authorized networks that are
configured.

There is a (private, sorry) [Pivotal Tracker
story](https://www.pivotaltracker.com/n/projects/975916/stories/133642819) to
address this issue.


## Troubleshooting

#### Error message: ####
   ```
   google_sql_user.diego: Creating...
     host:     "" => "%"
     instance: "" => "ph-concourse-terraform-piglet"
     name:     "" => "admin"
     password: "<sensitive>" => "<sensitive>"
   Error applying plan:

   1 error(s) occurred:

   * google_sql_user.diego: 1 error(s) occurred:

   * google_sql_user.diego: Error, failure waiting for insertion of admin into ph-concourse-terraform-piglet: Error waiting      for Insert User (op 44940cc3-df8a-4d86-9bb8-853540fa4f35): googleapi: Error 404: The Cloud SQL instance operation does not    exist., operationDoesNotExist
   ```
   
   **Solution:** You cannot use "admin" as a username for MySQL. 
   
   
   #### Error message: ####
   ```
   “{”errors”:{“.properties.networking_point_of_entry.external_ssl.ssl_ciphers”:[“Value can’t be blank”]}}”
   ```
   
   **Solution:** pcf-pipelines is not compatible with ERT 1.11.14. Redeploy with a [compatible](https://github.com/pivotal-cf/pcf-pipelines#install-pcf-pipelines) version. 
   
   
   
#### Error message: ####

    Error
    pcf-pipelines/tasks/stage-product/task.sh: line 19: ./pivnet-product/metadata.json: No such file or directory



  **Solution:** You are not using the PivNet resource, and are most likely using a different repository manager like Artifactory. For more information, and a possible workaround, see this github [issue](https://github.com/pivotal-cf/pcf-pipelines/issues/192). 


#### Error message: ####

    Error
    initializing
    running pcf-pipelines/install-pcf/gcp/tasks/create-initial-terraform-state/task.sh
     ERROR: (gcloud.auth.activate-service-account) Missing required argument [ACCOUNT]: An account is required when using .p12 keys


  **Solution:** Ensure the `gcp_service_account_key` parameter is indented correctly. For example:
  ```  
  gcp_service_account_key: |
    {
      "type": "service_account",
      "project_id": "cf-example",
      "private_key_id": "REDACTED",
      "private_key": "-----BEGIN PRIVATE KEY-----...example...-----END PRIVATE KEY-----\n",
      "client_email": "customer0-example.iam.gserviceaccount.com",
      "client_id": "REDACTED",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://accounts.google.com/o/oauth2/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/customer0-example.iam.gserviceaccount.com"
    }
  ```
