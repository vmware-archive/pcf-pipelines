# Upgrade Ops Manager



1. Download the upgrade-ops-man pipeline from [Pivnet](https://network.pivotal.io/products/pcf-automation).

2. Configure your `params.yml` file.

   This file contains parameters for the pipeline and the secrets necessary to
   communicate with PivNet and OpsMan. Fill it out with the necessary values and
   store it in a safe place.

3. [Set the pipeline](http://concourse-ci.org/single-page.html#fly-set-pipeline), using your updated params.yml:

   ```
   fly -t lite set-pipeline -p upgrade-ops-man -c pipeline.yml -l params.yml
   ```

4. Unpause the pipeline. The pipeline should then start triggering automatically.


## Troubleshooting:

### Pipeline fails and govc returns multiple results

If you see this type of error, it is likely that you are using a space in the Ops Manager vm name. To resolve this issue, make sure your datacenter, cluster name, resource pool, and VM name does not contain a space.

### Ops Manager IP address swapping
The vSphere upgrade-ops-mgr pipelines currently do not detach the IP adddress from the old Ops Manager instance, once the new Ops Manager is added. This will be fixed soon. Similarly, on other IaaSes, the private IP address is not necessarily kept and re-used on the new Ops Manager instance.
