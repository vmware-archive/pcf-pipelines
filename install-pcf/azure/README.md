# Install PCF on AZURE 

#### This process describes how to get the pipeline and install a PCF on a properly configured AZURE
http://docs.pivotal.io/pivotalcf/1-10/refarch/azure/azure_ref_arch.html
**note: we do not currently bundle this pipeline in our artifacts published to network.pivotal.io. below is how to get the pipeline up and running**

```bash

# get the pipeline bits
$ git clone git@github.com:pivotal-cf/azure-concourse.git

# go to the pipeline dir
$ cd azure-concourse

# check the readme for pre-reqs and guidance
$ cat README.md

# fill in your environments specific values
$ vim ci/c0-azure-concourse-poc-params.yml

# send your pipeline to a concourse (targeting and logging in info can be found here: https://concourse.ci/fly-cli.html)
$ fly -t lite set-pipeline -p pcf -c ci/c0-azure-concourse-poc.yml -l ci/c0-azure-concourse-poc-params.yml

# unpause your pipeline
$ fly -t lite unpause-pipeline -p pcf

```
