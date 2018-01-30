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

Upload the [CredHub](http://bosh.io/releases/github.com/pivotal-cf/credhub-release?all=1)
and [UAA](http://bosh.io/releases/github.com/cloudfoundry/uaa-release?all=1) releases
to your BOSH director.

Then simply define the required variables and apply the operations files with `-o <file>`
as part of the `bosh deploy` command (CLI v2 only).  Variables can be defined in a YAML
file along with the `-l` flag, or specified inline on the command line with `-v VAR=VALUE`.

You may also use `bosh int` to view the interpolated manifest:

```
$ bosh int concourse.yml -o add-credhub-to-atc.yml -o replace-vault-with-credhub.yml
```

**Note:** CredHub integration requires Concourse 3.5.0 or later.
