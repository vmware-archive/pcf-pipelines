# concourse-tasks-bundle
this is a bundle of tasks to be composed into and executed by concourse pipelines

[![wercker
status](https://app.wercker.com/status/b7264dfb225630a0cfefbcc8c41a8062/s/master
"wercker
status")](https://app.wercker.com/project/byKey/b7264dfb225630a0cfefbcc8c41a8062)


## how to run tests
**once pushed to the remote your builds can be viewed in wercker
any push which passes all unit tests and can be cross compiled successfully will
be pushed to github as a draft release with cross platform binaries included
(https://app.wercker.com/enaml-ops/gemfire-plugin/runs)
### pre-reqs
  - docker
  - wercker cli 
  - (see: http://devcenter.wercker.com/docs/cli/installation)

```bash



# first run: this will always pull a fresh container image and not use anything
in your local cache

$> ./testrunner init

# or to use the cache (faster after first run)

$> ./testrunner

```
