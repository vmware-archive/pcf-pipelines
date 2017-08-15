# PCF on Azure

![Concourse Pipeline](embed.png)

This pipeline uses Terraform to create all the infrastructure required to run an
HA PCF deployment on Azure per the Customer[0] [reference
architecture](http://docs.pivotal.io/pivotalcf/1-10/refarch/azure/azure_ref_arch.html).

## Usage

This pipeline downloads artifacts from DockerHub (czero/cflinuxfs2 and custom
docker-image resources) and the configured Azure Storage Container
(terraform.tfstate file), and as such the Concourse instance must have access
to those. Note that Terraform outputs a .tfstate file that contains plaintext
secrets.

1. Create an Azure Active Directory Service Principal for your subscription with
the `Contributor` Role on the target Azure Project

Install jq:

On MacOS X:
```
brew install jq
```

On linux:
```
sudo apt-get install jq
```

or:

```
wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
  -O /usr/local/bin/jq
chmod +x /usr/local/bin/jq
```

Set your Subscription ID to the subscription that will be used by the install-pcf pipeline:

```
export SUBSCRIPTION_ID=<YOUR-SUBSCRIPTION-ID>
export SERVICE_PRINCIPAL_PASSWORD=<SOME-PASSWORD>
```

```
az ad app create --display-name "PCFServiceAccount" \
  --homepage "http://pcfserviceaccount" \
  --identifier-uris "http://pcfserviceaccount" \
  --password "$SERVICE_PRINCIPAL_PASSWORD" | tee app_create.json

export APP_ID="$(jq -r .appId app_create.json)"

az ad sp create --id "$APP_ID"

az role assignment create --assignee "http://pcfserviceaccount" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

2. Create an Azure Storage Account and Container to store terraform.tfstate

```
az group create --name "pcfci" \
  --location "WestUS"

az storage account create --name "pcfci" \
  --resource-group "pcfci" \
  --location "WestUS" \
  --sku "Standard_LRS"

AZURE_ACCOUNT_KEY=$(az storage account keys list --account-name pcfci --resource-group pcfci | jq -r .[0].value)

az storage container create --name terraformstate \
  --account-name pcfci
```

3. Clone this repo:

```
git clone https://github.com/pivotal-cf/pcf-pipelines.git
```

4. Update `pcf-pipelines/install-pcf/azure/params.yml` and replace all variables/parameters.

    - The sample pipeline params file includes 2 params that set the major/minor versions of
      OpsMan and ERT that will be pulled.  They will typically default to the latest RC/GA available tiles.
      ```
      opsman_major_minor_version: '1\.11\..*'
      ert_major_minor_version: '1\.11\..*'
      ```

5. Log into concourse and create the pipeline.

```
fly -t lite set-pipeline -p install-pcf-azure \
  -c pcf-pipelines/install-pcf/azure/pipeline.yml \
  -l pcf-pipelines/install-pcf/azure/params.yml
```

6. Un-pause the pipeline.

7. Run the `bootstrap-terraform-state` job. This will create a `terraform.tfstate` in your storage
container to be used by the pipeline.

8. Run the `create-infrastructure` job. This will create all the infrastructure necessary for your
PCF installation. `config-opsman-auth` will automatically trigger after `create-infrastructure`
and fail if step 9 isn't done. After step 9 is done the job can be ran again.

9. Create an NS record within the delegating zone with the name servers from the newly created zone.

Get the DNS zone created by terraform for your PCF ERT domain with the following:
```
az network dns zone show --name <PCF-ERT-DOMAIN>
```
