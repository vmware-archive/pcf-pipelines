# Install PCF on AWS 

#### This process describes how to get the pipeline and install a PCF on a properly configured AWS 
http://docs.pivotal.io/pivotalcf/1-10/refarch/aws/aws_ref_arch.html
**note: we do not currently bundle this pipeline in our artifacts published to network.pivotal.io. below is how to get the pipeline up and running**

```bash

# get the pipeline bits
$ git clone git@github.com:pivotal-cf/aws-concourse.git

# go to the pipeline dir
$ cd aws-concourse 

# check the readme for pre-reqs and guidance
$ cat README.md

# fill in your environments specific values
$ vim pcfaws_terraform_params.yml

# send your pipeline to a concourse (targeting and logging in info can be found here: https://concourse.ci/fly-cli.html)
$ cd ci
$ fly -t local set-pipeline -p pcf-aws-prepare -c pcfaws_terraform_pipeline.yml --load-vars-from pcfaws_terraform_params.yml

# unpause your pipeline
$ fly -t local unpause-pipeline -p pcf-aws-prepare

```
