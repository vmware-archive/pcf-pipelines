# PCF Fresh Installation Pipelines

Deploys PCF for whichever IaaS you choose. For public cloud installs, such as AWS, Azure, and GCP, the pipeline will deploy the necessary infrastructure in the public cloud, such as the networks, loadbalancers, and databases, and use these resources to then deploy PCF (Ops Manager and Elastic Runtime). On-premise private datacenter install pipelines, such as with vSphere and Openstack, do not provision any infrastructure resources and only deploy PCF, using resources that are specified in the parameters of the pipeline.

The desired output of these install pipelines is a PCF deployment that matches the [Pivotal reference architecture](http://docs.pivotal.io/pivotalcf/refarch), usually using three availability zones and opting for high-availability components whenever possible. If you want to deploy a different architecture, you may have to modify these pipelines to get your desired architecture.

## Prerequisites

- [install a Concourse server](https://concourse-ci.org/installing.html)
- download the [Fly CLI](https://concourse-ci.org/fly-cli.html) to interact with the Concourse server
- depending on where you've installed Concourse, you may need to set up
[additional firewall rules](FIREWALL.md "Firewall") to allow Concourse to reach
third-party sources of pipeline dependencies
- ensure you have set up DNS and certs correctly, for example, our pipelines require that you have set up the Ops Manager url with `opsman` as a prefix.


More information about these pipelines are found in each of the IAAS-specific directories:

- [AWS Install Pipeline](https://github.com/pivotal-cf/pcf-pipelines/tree/master/install-pcf/aws)
- [Azure Install Pipeline](https://github.com/pivotal-cf/pcf-pipelines/tree/master/install-pcf/azure)
- [GCP Install Pipeline](https://github.com/pivotal-cf/pcf-pipelines/tree/master/install-pcf/gcp)
- [OpenStack Install Pipeline](https://github.com/pivotal-cf/pcf-pipelines/tree/master/install-pcf/openstack)
- [vSphere Install Pipeline](https://github.com/pivotal-cf/pcf-pipelines/tree/master/install-pcf/vsphere)

