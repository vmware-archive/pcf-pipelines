# Upgrade Ops Manager

## Structure / Purpose
The subfolders of this directory are for specific IaaS impelementations. 
Each pipeline is meant to serve the same purpose on it's given IaaS. That
purpose is to automate the upgrade of an existing Ops Manager VM.

## Notes:

### Ops Manager VM Termination
This pipeline to upgrade Ops Manager, depending on the IaaS, may not actually terminate the original Ops Manager VM. This is in case any failures occur during the upgrade process, so that you can restart the original Ops Manager if you need to rollback to it. If the upgrade process is successful and you'd like to cleanup the shutdown Ops Manager, because it is no longer needed, then you can terminate it manually.

### SAML for AuthN on Ops Manager:
On Ops Manager using SAML-based authentication, 
a local admin user must be created on the Ops Manager's UAA before these pipelines
can be used to automate your Ops Manager Upgrade. This is b/c the `om` tool
we use for interacting with Ops Manager only supports user/pass authentication
Instructions on how to do this can be found here:
https://docs.cloudfoundry.org/adminguide/uaa-user-management.html

Required Scopes and authorities are :
- scope (list):  opsman.admin
- authorized grant types (list):  client_credentials
- authorities (list):  opsman.admin

## Known Issues:

### Ops Manager IP address swapping
The vSphere upgrade-ops-mgr pipelines currently do not detach the IP adddress from the old Ops Manager instance, once the new Ops Manager is added. This will be fixed soon. Similarly, on other IaaSes, the private IP address is not necessarily kept and re-used on the new Ops Manager instance.

### Tiles with Stemcells not Available on PivNet
For Ops Manager with tiles that require stemcells which are not available on PivNet, e.g. Apigee tiles, the setup of the pipeline requires an additional operations file that enables downloads from bosh.io.

```
cd pcf-pipelines
cat upgrade-ops-manager/gcp/pipeline.yml | yaml-patch -o operations/add-download-boshio-stemcell.yml \
  > upgrade-ops-manager/gcp/bosh-io-enabled-pipeline.yml
fly -t ci set-pipeline \
  -p gcp-upgrade-opsmanager \
  -c upgrade-ops-manager/gcp/bosh-io-enabled-pipeline.yml \
  -l params.yml \
  -v iaas_type=google
```
Possible values for `iaas_type` are: `aws`, `azure`, `vsphere` and `google`.
