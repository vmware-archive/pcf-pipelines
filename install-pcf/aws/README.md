Do NOT use username `admin` for any of database credentials that you configure for this pipeline.

## Known Issues

In the `create-infrastructure` job, there is a [race condition](https://github.com/terraform-providers/terraform-provider-aws/issues/877) whereby terraform creates the s3 bucket and as a final step performs a `get` on the bucket info. If, for some reason, the api call hits a node that hasn't yet been updated with the new bucket info, the terraform call fails (but a bucket actual exists). 

**Current workaround**: If the job fails with the aforementioned errors, manually trigger the job again. The next run of the job should complete successfully.


## Troubleshooting

#### Error message: ####
   ```
   “{”errors”:{“.properties.networking_point_of_entry.external_ssl.ssl_ciphers”:[“Value can’t be blank”]}}”
   ```
   
   **Solution:** pcf-pipelines is not compatible with ERT 1.11.14. Redeploy with a [compatible](https://github.com/pivotal-cf/pcf-pipelines#install-pcf-pipelines) version. 

#### Error message: ####
   ```
   Error applying plan:

   1 error(s) occurred:

   * google_sql_user.diego: 1 error(s) occurred:

   * google_sql_user.diego: Error, failure waiting for insertion of admin into ph-concourse-terraform-piglet
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
