# Secure credential automation with Vault and Concourse

Concourse allows for the [parameterization of pipelines](https://concourse-ci.org/fly-set-pipeline.html#parameters)
when you `fly` them but it will store the pipeline and the secrets in the
database as one single encrypted field.

This might work in some environments but if you need to create an extra layer
of security, (i.e., for compliance reasons and/or for better security practices)
you need to be able to obfuscate these secrets from the Concourse pipeline.

That is the reason why the Concourse team created a [Credential Management](https://concourse-ci.org/creds.html)
integration. Its first implementation is an integration with [Vault](https://www.vaultproject.io/)
and this README will outline how to get started.

There is an often overlooked aspect of distributed systems security
where Concourse and Vault can help. Credential rotation is crucial to keeping
systems secure and we can use these tools to remove human intervention and
automate the rotation of credentials.

### Getting Started

#### Requirements:
- [Concourse](http://concourse-ci.org/installing.html) - We are assuming it is BOSH
installed in this post but it is not required.
- [Vault](https://github.com/cloudfoundry-community/vault-boshrelease)

These instructions assume that you already have a Vault server up and running.
For more information, refer to
[Vault's installation documentation](https://www.vaultproject.io/docs/install/index.html)
or the [Vault Bosh release](https://github.com/cloudfoundry-community/vault-boshrelease)
and this [sample deployment file](https://github.com/rahul-kj/concourse-vault/blob/master/vault.yml).

### Create a Vault read-only token for Concourse

We will need a read-only token for Concourse so it can access the Vault secret.
First, we have to create the Vault policy:

1. Login to Vault:
  `vault auth <token>`
1. Create a mount in value for use by Concourse pipelines
  `vault mount -path=/concourse -description="Secrets for concourse pipelines" generic`
1. Create a file with the policy
(e.g. [`policy.hcl`](https://github.com/rahul-kj/concourse-vault/blob/master/vault-policy.hcl)):
    ```concourse.hcl
    # concourse.hcl
    path "/concourse/*" {
      policy = "read"
      capabilities = ["read", "list"]
    }
    ```
1. Upload the policy to Vault:
  ` $ vault write sys/policy/concourse rules=@concourse.hcl `
1. Create a periodic token:
  ` $ vault token-create -period="2h" -orphan -policy=concourse`

Store the token since we will use it in the Concourse manifest.


### Connect Concourse to Vault

Setting up Concourse to use Vault for credential management is very
straightforward given the new integration. You just have to pass in some
parameters in the Concourse manifest to enable the communication. Here is an
example:

```
- ...
  instances: 1
  jobs:
  - name: atc
    properties:
      ...
      vault:
        path_prefix: /concourse
        auth:
          client_token: <TOKEN FROM PREVIOUS STEP>
        tls:
          ca_cert:
            certificate: |-
              -----BEGIN CERTIFICATE-----
              <VAULT CA CERTIFICATE>
              -----END CERTIFICATE-----
        url: <VAULT URL/IP>
    release: concourse
 ```

[Click here](https://github.com/rahul-kj/concourse-vault/blob/master/concourse.yml)
for an example of a complete Concourse deployment manifest with Vault integration.

For a complete list of Vault integration parameters for the `atc` job, please
consult the [ATC job's documentation](https://bosh.io/jobs/atc?source=github.com/concourse/concourse#p=vault).

Once you add this section to the manifest Concourse should now be able to read
from Vault.

### How to use it
To use Vault secrets in Concourse pipelines you have to parametrize your
pipeline with parentheses `(())` instead of curly brackets `{{}}`. Concourse
currently supports only one credential management system at a time with one
set of credentials, so if you specify a parameter, it will look it up in the
instance you linked Concourse to.

There are two formats that Concourse will look to find a credential. Concourse
will first look for pipeline scoped variables at
`/concourse/<team-name>/<pipeline-name>/<variable-name>`,
if this doesn't exist then it will look for team scoped variables at
`/concourse/<team-name>/<variable-name>`. This is useful when you want to share
credentials across multiple pipelines e.g keys, tokens, etc.

Not everything in a pipeline can be parametrized, you can read more about what
can be parametrized in the [Concourse docs](http://concourse-ci.org/creds.html#what-can-be-parameterized).
Basically you can pull secrets in `source` or `params` sections of a pipeline.

Here is an example:
Let's say we have a pipeline that deploys an application to  Pivotal Cloud
Foundry. You will need a resource that has the credentials to be able to push
the app. This is what it would look like:
```
resources:
- name: resource-deploy-web-app
  type: cf
  source:
    api: https://api.run.pivotal.io
    username: ((cf_username))
    password: ((cf_password))
    organization: ((cf_organization))
    space: ((cf_space))
    skip_cert_check: false
```

If we set the pipeline on the team `main` with the name `deploy-app`.
Concourse will look in Vault for `/concourse/main/deploy-app/cf_username`
first and `/concourse/main/cf_username` second.

### How to rotate credentials

Vault doesn't currently support random credential generation or versioning of
secrets. Because of that, we have to be careful when writing new secrets to Vault.

If the secret that we are writing to Vault is not the currently valid one we
will lose track of it.

To rotate credentials:

- Create a new random secret
- Store it into Vault with a suffix (like: `/concourse/main/cf_password_new`)
- Change the secret in the service (in this case run `cf passwd`)
- Store it into Vault again with the full name (`/concourse/main/cf_password`)

This way you can rotate credentials without having to worry about all the
places you have to change it. Once it is stored in Vault all other services
should be able to reference it from that point forward.
**Concourse will not require to be notified about this change, it will just
use the latest secret from Vault**.
