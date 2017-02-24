# Upgrade Ops Manager

## Structure / Purpose
The subfolders of this directory are for specific IaaS impelementations. 
Each pipeline is meant to serve the same purpose on it's given IaaS. That
purpose is to automate the upgrade of an existing Ops Manager VM.

## Notes:

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

# Concourse worker considerations
Due to the size of current Ops Manager installation.zip files you will need to modify the worker vm to allow
larger btrfs store size.
The size of the installation.zip file is based on how many tiles you have installed at the time. Dependng on the number
of tiles installed this setting could need to be as big as 50G. In a future release the size of this file should be decreasing.

'''
properties:
      garden:
        garden.btrfs_store_size_mb: 
'''
