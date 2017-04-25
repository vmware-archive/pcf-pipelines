# Upgrade Ops Manager

## Structure / Purpose
The subfolders of this directory are for specific IaaS impelementations. 
Each pipeline is meant to serve the same purpose on it's given IaaS. That
purpose is to automate the upgrade of an existing Ops Manager VM.

## Notes:

### Ops Mgr VM Termination
This pipeline to upgrade Ops Mgr, depending on the IaaS, may not actually terminate the original Ops Mgr VM. This is in case any failures occur during the upgrade process, so that you can restart the original Ops Mgr if you need to rollback to it. If the upgrade process is successful and you'd like to cleanup the shutdown Ops Mgr, because it is no longer needed, then you can terminate it manually.

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
