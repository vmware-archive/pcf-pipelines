# Install PCF on GCP 

#### This process describes how to get the pipeline and install a PCF on a properly configured GCP
http://docs.pivotal.io/pivotalcf/1-10/refarch/gcp/gcp_ref_arch.html
**note: we do not currently bundle this pipeline in our artifacts published to network.pivotal.io. below is how to get the pipeline up and running**

```bash

# get the pipeline bits
$ git clone git@github.com:pivotal-cf/gcp-concourse.git

# go to the pipeline dir
$ cd gcp-concourse 

# check the readme for pre-reqs and guidance
$ cat README.md

# fill in your environments specific values
$ vim params.yml

# send your pipeline to a concourse (targeting and logging in info can be found here: https://concourse.ci/fly-cli.html)
$ fly -t lite set-pipeline -p deploy-pcf -c pipeline.yml -l params.yml

# unpause your pipeline
$ fly -t lite unpause-pipeline -p deploy-pcf

```
