# PCF on AWS

![Concourse Pipeline](embed.png)

This pipeline uses Terraform to create the infrastructure required to run a
3 AZ PCF deployment on AWS per the Customer[0] [reference
architecture](http://docs.pivotal.io/pivotalcf/refarch/aws/aws_ref_arch.html).

## Usage

This pipeline downloads artifacts from DockerHub (czero/rootfs and custom
docker-image resources) and the configured S3 bucket
(terraform.tfstate file), and as such the Concourse instance must have access
to those. Note that Terraform outputs a .tfstate file that contains plaintext
secrets.

1. Create a versioned bucket for holding terraform state.

2. Ensure [the prerequisites are met](https://docs.pivotal.io/pivotalcf/1-12/customizing/aws.html#prerequisities), in particular:

* A key pair to use with your PCF deployment. For more information, see the AWS documentation about [creating a key pair](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-keypair.html).
* Create a public DNS zone, get its zone ID and place it in params.yml under `ROUTE_53_ZONE_ID`
* [Generate a certificate](http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-server-cert.html#create-cert) for the domain used in the public DNS zone.

3. Change all of the CHANGEME values in params.yml with real values.

4. [Set the pipeline](http://concourse.ci/single-page.html#fly-set-pipeline), using your updated params.yml:
  ```
  fly -t lite set-pipeline -p deploy-pcf -c pipeline.yml -l params.yml
  ```

5. Unpause the pipeline

6. Run `bootstrap-terraform-state` job manually. This will prepare the s3 resource that holds the terraform state. This only needs to be run once.

7. `create-infrastructure` will automatically upload the latest matching version of Operations Manager

8. Once DNS is set up you can run `configure-director`. From there the pipeline should automatically run through to the end.

### Tearing down the environment

There is a job, `wipe-env`, which you can run to destroy the infrastructure
that was created by `create-infrastructure`.

If you want to bring the environment up again, run `create-infrastructure`.

Do NOT use username `admin` for any of database credentials that you configure for this pipeline.

## Known Issues

#### Issue: #### 
If you are using pcf-pipelines v23, the functionality for entering certs for `networking_poe_ssl_certs` does not currently work. Functionality does work if you choose to leave `networking_poe_ssl_certs` blank. The fix for the aforementioned issue will be released soon. 

## Troubleshooting

#### Error message: ####
   ```
   “{”errors”:{“.properties.networking_point_of_entry.external_ssl.ssl_ciphers”:[“Value can’t be blank”]}}”
   ```

   **Solution:** pcf-pipelines is not compatible with ERT 1.11.14. Redeploy with a [compatible](https://github.com/pivotal-cf/pcf-pipelines#install-pcf-pipelines) version. 

#### Error message: ####
   ```
   failure waiting for insertion of admin into ph-concourse-terraform-test
   ...
   operationDoesNotExist
   ```
   
   **Solution:** For AWS Aurora, you cannot use "admin" as a username for MySQL. 
   
   
#### Error message: ####  

    Error 100: CPI error 'Bosh::Clouds::CloudError' with message 'Unable to create a connection to AWS. Please check your         provided settings: Region 'us-east-1', Endpoint 'Not provided'.
    IaaS Error: #<Seahorse::Client::NetworkingError: execution expired>' in 'info' CPI method
    
   
   **Solution:** Check your AMI for the NAT boxes.


#### Error message: ####

    ssh: Could not resolve hostname opsman.sle1.aws.customer0.net: Name or service not known
    lost connection



   **Solution:** The parent zone (aws.customer0.net) is not delegating to the zone created via terraform. You need to add the NS records for (sle1.aws.customer0.net) in the parent zone in AWS Route53. 
   

#### Error message: ####

    Error
    pcf-pipelines/tasks/stage-product/task.sh: line 19: ./pivnet-product/metadata.json: No such file or directory



   **Solution:** You are not using the PivNet resource, and are most likely using a different repository manager like Artifactory. For more information, and a possible workaround, see this github [issue](https://github.com/pivotal-cf/pcf-pipelines/issues/192).

#### Error: ####

   The `create-infrastructure` job is waiting for `terraform-state` indefinitely.

   **Solution:** Run the `bootstrap-terraform-state` job to create an initial
   `terraform.tfstate` in the `terraform-state` bucket. The `create-infrastructure`
   job depends on a `terraform.tfstate` to exist before it can be run.
