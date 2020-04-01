# CredHub + Concourse

This directory contains BOSH [operations files](https://bosh.io/docs/cli-ops-files.html)
to set up CredHub integration with Concourse:

- `add-credhub-to-atc.yml`: Colocates CredHub + UAA on the Concourse ATC instances
- `replace-vault-with-credhub`: Replace Concourse's Vault configuration with CredHub

The operations are split into separate files to allow for a two-phased migration
from Vault to CredHub.  Some teams may decide to deploy CredHub alongside Concourse
while still using Vault as a first step.  This gives the team a chance to learn
CredHub, verify that Concourse is still operational with a colocated CredHub and
UAA, and load CredHub with secrets prior to disabling the Vault integration.

## Usage

These ops files were written with [`concourse-bosh-deployment`](https://github.com/concourse/concourse-bosh-deployment)
in mind.

Then simply define the required variables and apply the operations files with `-o <file>`
as part of the `bosh deploy` command (CLI v2 only).  Variables can be defined in a YAML
file along with the `-l` flag, or specified inline on the command line with `-v VAR=VALUE`.

For example, your command may look something like the following.

Note: this is a representative example, you will want to consult the
full gamut of operations files provided by `concourse-bosh-deployment`
to determine which options are suitable for your deployment.

```
$ bosh deploy -d concourse ~/concourse-bosh-deployment/cluster/concourse.yml \
   -l ~/concourse-bosh-deployment/versions.yml \
   -o concourse-bosh-deployment/cluster/operations/tls.yml \
   -o concourse-bosh-deployment/cluster/operations/tls-vars.yml \
   -o add-credhub-to-atcs.yml \
   -o replace-vault-with-credhub.yml \
   -v deployment_name=concourse \
   -v network_name=default \
   -v worker_vm_type=medium \
   -v web_vm_type=medium \
   -v db_vm_type=medium \
   -v uaa_release_version=60 \
   -v uaa_sha=a7c14357ae484e89e547f4f207fb8de36d2b0966 \
   -v credhub_release_version=1.9.3 \
   -v credhub_sha=648658efdef2ff18a69914d958bcd7ebfa88027a \
   -v db_persistent_disk_type=100GB \
   -v external_url=http://concourse.example.com \
   -v external_hostname=concourse.example.com
```

**Note:** CredHub integration requires Concourse 3.5.0 or later.
