# Guide To Install PCF on GCP

![Concourse Pipeline](embed.png)

This pipeline uses Terraform to create all the infrastructure required to run a
3 AZ PCF deployment on GCP per the Customer[0] [reference
architecture](http://docs.pivotal.io/pivotalcf/1-10/refarch/gcp/gcp_ref_arch.html).

## GCP Infrastructure Preparation

### 1. Enable Relevant GCP APIs

Below APIs must be enabled before proceeding:
- GCP Compute API [here](https://console.cloud.google.com/apis/api/compute_component)
- GCP Storage API [here](https://console.cloud.google.com/apis/api/storage_component)
- GCP SQL API [here](https://console.cloud.google.com/apis/api/sql_component)
- GCP DNS API [here](https://console.cloud.google.com/apis/api/dns)
- GCP Cloud Resource Manager API [here](https://console.cloud.google.com/apis/api/cloudresourcemanager.googleapis.com/overview)
- GCP Storage Interoperability [here](https://console.cloud.google.com/storage/settings)

### 2. Create Bucket In GCP Cloud Storage for Terraform

- Manually create the bucket with an arbitary name, e.g. `terraform-state-for-pcf`, which must be globally unique
- Enable versioning for this bucket, open GCP Cloud Shell (>_) and run:
  ```
  $ gsutil versioning set on gs://terraform-state-for-pcf
  Enabling versioning for gs://terraform-state-for-pcf/...
  $ gsutil versioning get gs://terraform-state-for-pcf
  gs://terraform-state-for-pcf: Enabled
  ```

### 3. Create Service Account 

In GCP, navigate to **IAM & Admin -> Service Accounts**, create a new service account, say `pcf-service-account`, that has the following IAM roles:
- Cloud SQL Admin
- Compute Instance Admin (v1)
- Compute Network Admin
- Compute Security Admin
- DNS Administrator
- Storage Admin


## Work With The Concourse Pipeline

### 1. Clone `pcf-pipeline`

```
$ git clone https://github.com/pivotal-cf/pcf-pipelines.git
$ cd pcf-pipelines/install-pcf/gcp
$ cp params.yml params-mine.yml
```
*Note: having a local version of params.yml, say `params-mine.yml`, is always a good idea*

### 2. Prepare The ERT Cert & Private Key

See `Known Issue` for why we need to do this in GCP.

Below are the sample commands and configurations for preparing a simple self-signed cert for this deployment.

Do remember to change like domain name etc. to fit your situation.

```
$ echo "
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn
[ dn ]
C=US
ST=CA
L=SAN FRANCISCO
O=Mycompany
OU=APJ
emailAddress=myemail@mycompany.com
CN = *.pcf.mycompany.com
[ req_ext ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = *.sys.pcf.mycompany.com
DNS.2 = *.cfapps.pcf.mycompany.com
DNS.3 = *.login.sys.pcf.mycompany.com
DNS.4 = *.uaa.sys.pcf.mycompany.com
" > ert.cnf

$ openssl req -new -sha256 -nodes -out ert.csr -newkey rsa:2048 -keyout ert.key -config ert.cnf

$ openssl req -text -noout -verify -in ert.csr

$ openssl x509 -req -days 3650 -in ert.csr -signkey ert.key -out ert.crt -extensions req_ext -extfile ert.cnf

$ openssl x509 -in ert.crt -text
```

*Note:*
- without cert generated prior to running the pipeline, we can simply set `pcf_ert_ssl_cert: generate` in param.yml but it may cause you more troubles -- see **known issue** for details

### 3. Configure The `params-mine.yml`

The comments/instructions in the default `params.yml` are good but I'd like to highlight some parameters here:
- `gcp_service_account_key`: this must be the whole json file downloaded after creation of GCP service account
- `gcp_resource_prefix`: this prefix will be added to all GCP resources, like VPC, buckets, Firewall rules, load balancers etc. which help us easily to identify
- `opsman_domain_or_ip_address`: this is the new param changed from `opsman_uri`. If you're facing errors, while working on `configure-bosh` job, like `could not execute "configure-bosh": could not fetch form: failed during request: token could not be retrieved from target url: Post https:///uaa/oauth/token: http: no Host in request URL`, it's really because the right opsman host hasn't been properly set
- `pcf_ert_ssl_cert` and `pcf_ert_ssl_key`: these are where the certificate/key we generated for ERT should be set to
- all `db_XXX_username` and `db_XXX_password` must set the right value regardless there is a CHANGEME or not

### 4. Setup the Concourse and set the pipeline

Set the pipeline:

`fly -t pcf set-pipeline -p deploy-pcf -c pipeline.yml -l params-mine.yml`

And unpause it:

`fly -t pcf unpause-pipeline -p deploy-pcf`

*Note: I'd suggest you to set up the Concourse within GCP.*

### 5. Trigger `bootstrap-terraform-state` Job Manually

This job is to bootstrap Terraform and needs to be run once.
A `terraform.tfstate` file, for holding the Terraform state, will be generated and put in GCP Storage bucket we just generated, e.g. `terraform-state-for-pcf`.

### 6. Trigger `upload-opsman-image` Job Manually

This job is to download the latest matching version of Operations Manager from [PivNet](https://network.pivotal.io/products/ops-manager) to GCP as image.

### 7. Trigger `create-infrastructure` Job Manually

This job is to create the required infrastructure resources in GCP which include:
- Images: stemcells etc.
- SQL: one SQL instance, with necessary users, databases, permissions etc., will be created for ERT
- VPC: one VPC with 3 subnets (infrastructure, ert, services) will be created
- Firewall rules: a series of firewall rules will be created
- Instance Groups: 3 instance groups will be created
- Load Balancers: 4 load balancers with necessary health checks will be created
- Cloud DNS: one Cloud DNS zone will be created
- VM Instances: 3 NAT servers will be created

*Note: this step may have to re-run several times if you encountered issues -- try to fix them before re-running it*

### 8. Configure The DNS

Above step will output the DNS and IPs and these must be created and activated as A records, in the DNS service provider of your choice, like godaddy.com, before continuing:

- IP from HTTP(S) Load Balancer of *-global-pcf
  * *.cfapps.pcf
  * *.sys.pcf

- IP from TCP Load Balancer of *-ssh-proxy
  * ssh.sys.pcf

- IP from TCP Load Balancer of *-wss-logs
  * doppler.sys.pcf
  * loggregator.sys.pcf

- IP from TCP Load Balancer of *-cf-tcp-lb
  * tcp.pcf

- IP from Ops Manager:
  * opsman.pcf

*Note: make sure all DNS A records work by using `dig` command like `dig doppler.sys.pcf.xxx.com` before continuing*

### 9. Trigger `configure-director` Job Manually

Manually trigger `configure-director` job and the rest of the jobs will be automatically run through to the end.
- `deploy-director`: this job will deploy the OpsManager Director by OPS Manager APIs
- `upload-ert`: this job will download ERT from [PivNet](https://network.pivotal.io/products/elastic-runtime) and upload it to OpsManager Director
- `deploy-ert`: this job will deploy ERT with default HA configuration

Once you successfully ran through the pipeline, congratulations! You've gotten the whole Ops Manager + OpsManager Director + ERT up and running!

*Note:* 
- As the ERT size is not small, make sure the Concourse worker VM has at least 25G disk
- We may log into Ops Manager to fine tune some configurations after the pipeline has been gone through


## Tearing down the environment

The pipeline provides a job named `wipe-env` for wiping out the GCP resources created by `create-infrastructure` job.

Before triggering this job, some manually works *may* have to be done first:
- Manually delete ERT (spun up by this pipeline) and any other tiles (if you installed manually after) and `apply changes` in Ops Manager
- Trigger `wipe-env` job manually to destroy the infrastructure resources that was created by `create-infrastructure` job.

*Note:*
- This job currently is not all-encompassing. You may have to manually delete ERT and other tiles/products in Ops Manager, as well as the OpsManager Director VM in GCP, before proceeding with `wipe-env`. This will be handled automatically in the future;
- If you want to bring the environment up again, simply run `create-infrastructure`.


## Known Issues

### `create-infrastructure` job trying to delete SSL cert in use

If you set `pcf_ert_ssl_cert: generate` in `params-mine.yml`, when the `create-infrastructure` job runs, it may generate an error like this:

```google_compute_ssl_certificate.ssl-cert (destroy): 1 error(s) occurred:
google_compute_ssl_certificate.ssl-cert: Error deleting ssl certificate: googleapi: Error 400: The ssl_certificate resource 'projects/<redacted>/global/sslCertificates/<redacted>-gcp-lb-cert' is already being used by 'projects/<redacted>/global/targetHttpsProxies/<redacted>-gcp-https-proxy', resourceInUseByAnotherResource
```
This is a known issue [#106](https://github.com/pivotal-cf/pcf-pipelines/issues/106).
When this happens, after you've initially run `create-infrastructure`, update your `params-mine.yml` and `set-pipeline` again to supply the generated certs so they aren't recreated.
Or you may simply follow the steps provided above to generate the cert prior to running this job.

### Missing Jumpbox

* There is presently no jumpbox installed as part of the Terraform scripts. If you need to SSH onto the Ops Manager VM you'll need to add an SSH key from within GCP to the instance, and also add the `allow-ssh` tag to the network access tags.

### Cloud SQL Authorized Networks

There is a set of authorized networks added for the Cloud SQL instance which has been modified to include 0.0.0.0/0. This is due to Cloud SQL only managing access through public networks. We don't have a good way to keep updated with Google Compute Engine CIDRs, and the Google Cloud Proxy is not yet available on BOSH-deployed VMs. Thus, to allow Elastic Runtime access to Cloud SQL, we allow 0.0.0.0/0. When a better solution comes around we'll be able to remove it and allow only the other authorized networks that are configured.

There is a (private, sorry) [Pivotal Tracker story](https://www.pivotaltracker.com/n/projects/975916/stories/133642819) to address this issue.