## Known Issues

In the `create-infrastructure` job, there is a [race condition](https://github.com/terraform-providers/terraform-provider-aws/issues/877) whereby terraform creates the s3 bucket and as a final step performs a `get` on the bucket info. If, for some reason, the api call hits a node that hasn't yet been updated with the new bucket info, the terraform call fails (but a bucket actual exists). 

**Current workaround**: If the job fails with the aforementioned errors, manually trigger the job again. The next run of the job should complete successfully.
