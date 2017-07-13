# PCF on OpenStack

![Concourse Pipeline](embed.png)

This pipeline uses Terraform to create all the infrastructure required to run a
3 AZ PCF deployment on Openstack per the Customer[0] [reference
architecture](http://docs.pivotal.io/pivotalcf/1-10/refarch/openstack/openstack_ref_arch.html).

## Usage

This pipeline downloads artifacts from DockerHub (czero/cflinuxfs2 and custom
docker-image resources) and Pivotal Network, and as such the Concourse instance
must have access to those.

1. Create/upload a keypair if you have not already done so:

    ```
    openstack keypair create
    ```
    
2. Allocate a floating IP for the Ops Manager VM if you have not done so. You
   should create a DNS entry for this IP and use that entry as your 
   `opsman_uri`. This value will be used for `opsman_floating_ip` in `params.yml`.
   
   ```
   openstack floating ip create <ext_network_name>
   ```

3. Change all of the `#CHANGEME` values in params.yml with real values. Change
   any other values you want in `params.yml` to reflect your deployment.

   - `external_network` should be set to whatever network floating ips live on

   - Network DNS servers should be set (only 1 server can be specificed):
   
     ```
     infra_dns
     ert_dns
     services_dns
     dynamic_services_dns
     ```

   - Network AZs must be set to a comma-seperated list of az values that the
     networks will live in:

       ```
       infra_nw_azs
       ert_nw_azs
       services_nw_azs
       dynamic_services_nw_azs
       ```

   - The OS connection variables must be set:

     ```
     os_auth_url
     os_identity_api_version
     os_username
     os_password
     os_user_domain_name
     os_project_name
     os_project_id
     os_tenant
     os_region_name
     os_interface
     pre_os_cacert
     ```

   - Set your az names:

     ```
     az_01_name
     az_02_name
     az_03_name
     ```

   - Set `ert_singleton_job_az` to whichever availability zone single jobs
     should be deployed to.

   - Set `pivnet_token` to your Pivotal Network API token

   - Change Ops Manager VM settings:
 
    ```
    opsman_key
    opsman_floating_ip
    opsman_uri
    opsman_admin_username
    opsman_admin_password
    om_decryption_pwd
    ``` 
    
  - Change the Ops Man Director settings:
  
    ```
    ntp_servers
    os_keypair_name
    os_private_key
    ```
    
  - Set `ssl_termination_point` based on your Load Balancer solution (See 
    [Deploying with internal HAProxy](#deplying-with-internal-haproxy) for 
    dev/test purposes)
  
  - Set `om_generate_ssl_endpoint`
  
  - Set `security_acknowledgement` to `X`
  
  - Set PCF domain names (system/apps):
  
    ```
    system_domain
    apps_domain
    ```
    
  - Set `mysql_monitor` e-mail address

4. [Set the pipeline](http://concourse.ci/single-page.html#fly-set-pipeline), using your updated params.yml:

    ```
    fly -t lite set-pipeline -p deploy-pcf -c pipeline.yml -l params.yml
    ```

5. Unpause the pipeline
6. Trigger the `create-infrastructure` job.

### Deplying with internal HAProxy

Before deploying determine what static IP in the `ert` pool will be used for 
the HAProxy instance. Wildcard DNS entries should be created for this static
IP address for your sys, apps, uaa and login domains. Alternative a service
like `xip.io` or `nip.io` could be used.

The following values should be set in `params.yml`:

  - `ssl_termination_point` should be set to `haproxy`
  - `ha_proxy_ips` should be set to the static IP which you created the DNS
    entries for earlier
  - `ha_proxy_instances` should be set to `1`

### Tearing down the environment

There is a job, `wipe-env`, under the `teardown` group, which you can run to 
destroy the foundation and infrastructure deployed by the pipeline.

If you want to bring the environment up again, run `create-infrastructure`.

## Known Issues

### Single AZ

Currently this pipeline only supports a single AZ deployment. Once a test
environment with multiple AZs is available, this functionality will be fully
fleshed out and incorporated into the pipeline. In the meantime, the other
two AZ defintions can remain commented out.

### MySQL Monitor

There is the possibilty of random running into `deploy-ert` failures with
the `mysql_monitor` job failing to start. This is a known issue and can
currently only be fixed by scaling down the `mysql_monitor` job to 0 instances
after editing a metadata file on the Ops Manager vm. You can run the following
steps as a workaround to this issue, and then re-run the `configure-ert` and
`deploy-ert` steps:

  - ssh into Ops Manager,
  - `sudo grep "Pivotal Elastic Runtime" /var/tempest/workspaces/default/metadata/*` 
  - `sudo vi the newest file`
  - search "name: mysql_monitor" job,
  - remove below section from the instance_definition of the job:
    ```
    zero_if:
      property_reference: ".properties.system_database"
      property_values:
      - external
    ```
  - Change `mysql_monitor_instances` to `0` in your `params.yml` and fly the changes
  
After a successful deployment, navigate to the Ops Man UI and change the value
for MySQL Monitor Instances back to 1 and apply changes
  - "Ops Manger > ERT > Resource Config", Apply Change.

### Missing Jumpbox
* There is presently no jumpbox installed as part of the infrastructure creation.
