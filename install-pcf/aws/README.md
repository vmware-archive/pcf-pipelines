# Prepare AWS for PCF install
## Concourse pipeline

## Prerequisites

Before start kicking off the pipeline, there are a few parameters need to be set. Here is a sample parameters file [sample_file](params.yml.sample)

* An admin account to provision AWS resources (Networks, Load Balancers ... )

  ```
  Params:
    TF_VAR_aws_access_key: XXXXXXXXXXXXXXXXXXXX
    TF_VAR_aws_secret_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  ```

* Decide a domain for elastic runtime e.g pivotal-c0.com. The pipeline will use prefix apps and sys for wild card domains:

   ```
   *.apps.pivotal-c0.com
   *.sys.pivotal-c0.com
   ```

   ```
   Params:
     ERT_DOMAIN: pivotal-c0.com
   ```

* Upload a Cloud Foundry wild card certificate as server certificate to AWS [Upload Certificate ](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_server-certs.html#upload-server-certificate)

  ```
  Params:
    TF_VAR_aws_cert_arn: arn:aws:acm:us-east-1:XXXX:certificate/XXXXX
  ```


* Create an AWS key pair

  ```
  Params:
    TF_VAR_aws_key_name: XXXXX
    PEM: "-----BEGIN RSA PRIVATE KEY-----\n
    -----END RSA PRIVATE KEY-----"    
  ```


* Versioned s3 bucket to store terraform state files.

  ```
    S3_ENDPOINT: https://s3.amazonaws.com
    S3_OUTPUT_BUCKET: terraform-state-c0
  ```

* Other Parameters

  * AWS RDS username and password

    Pipeline creates a rds database that users can specify username and password in advance
    ```
      TF_VAR_rds_db_username: bosh
      TF_VAR_rds_db_password: boshbosh
    ```  

  * AWS prefix for provisioned resources.

    This is used to differentiate different deploy environment by prefixing the AWS resources (E.g. ELB and S3 buckets)

    ```
      TF_VAR_environment: sandbox
    ```

  *  Ops Manager AWS AMI

    ```
    TF_VAR_opsman_ami: ami-52c5e145
    ```

  * NAT Box AMI

    Pipeline creates three nat boxes across all availability zones

    ```
    TF_VAR_amis_nat: ami-303b1458
    ```

  * Region and three availability zones

    ```
    TF_VAR_aws_region: us-east-1
    TF_VAR_az1: us-east-1a
    TF_VAR_az2: us-east-1b
    TF_VAR_az3: us-east-1d
    ```

  * IP configuration

    Pipeline uses five types of network: Public, Elastic Runtime, Services and RDS and Infrastructure networks

    * Public Network: Ops manager and Nat boxes who needs public internet accessible through internet gateway
    * Elastic Runtime network: Cloud Foundry components, **three subnets on three AZs to achieve HA**
    * Services network: Deploy PCF tile services, **three subnets on three AZs to achieve HA**
    * RDS network: Deploy RDS databases, **three subnets on three AZs to achieve HA**
    * Infrastructure network: Deploy Bosh director

    ```
    TF_VAR_vpc_cidr: 192.168.0.0/16
    TF_VAR_public_subnet_cidr_az1: 192.168.0.0/24
    TF_VAR_public_subnet_cidr_az2: 192.168.1.0/24
    TF_VAR_public_subnet_cidr_az3: 192.168.2.0/24
    TF_VAR_ert_subnet_cidr_az1: 192.168.16.0/20
    ert_subnet_reserved_ranges_z1: 192.168.16.0 - 192.168.16.10
    TF_VAR_ert_subnet_cidr_az2: 192.168.32.0/20
    ert_subnet_reserved_ranges_z2: 192.168.32.0 - 192.168.32.10
    TF_VAR_ert_subnet_cidr_az3: 192.168.48.0/20
    ert_subnet_reserved_ranges_z3: 192.168.48.0 - 192.168.48.10
    TF_VAR_services_subnet_cidr_az1: 192.168.64.0/20
    services_subnet_reserved_ranges_z1: 192.168.64.0 - 192.168.64.10
    TF_VAR_services_subnet_cidr_az2: 192.168.80.0/20
    services_subnet_reserved_ranges_z2: 192.168.80.0 - 192.168.80.10
    TF_VAR_services_subnet_cidr_az3: 192.168.96.0/20
    services_subnet_reserved_ranges_z3: 192.168.96.0 - 192.168.96.10
    TF_VAR_infra_subnet_cidr_az1: 192.168.6.0/24
    infra_subnet_reserved_ranges_z1: 192.168.6.0 - 192.168.6.10
    TF_VAR_rds_subnet_cidr_az1: 192.168.3.0/24
    TF_VAR_rds_subnet_cidr_az2: 192.168.4.0/24
    TF_VAR_rds_subnet_cidr_az3: 192.168.5.0/24
    TF_VAR_opsman_ip_az1: 192.168.0.7
    TF_VAR_nat_ip_az1: 192.168.0.6
    TF_VAR_nat_ip_az2: 192.168.1.6
    TF_VAR_nat_ip_az3: 192.168.2.6
    ```

  * [Pivotal Net](https://network.pivotal.io) Token to download tiles

    ```
    PIVNET_TOKEN: XXXXXX
    ```

  * A github access key to download github binary releases E.g. https://github.com/pivotal-cf/om

    ```
    GITHUB_TOKEN: XXXXXX
    ```

  * IP Prefix:

    ** Note ** : Current pipeline creates only 10.0.0.0/16 VPC CIDR. Will expose configurable CIDR later

    ```
    IP_PREFIX: 10.0
    ```

  * ERT Cert:

    ** Note ** : Since pipeline uses pre load AWS server certificate. Currently these parameters are not used.

    ```    
     ERT_SSL_CERT: generate
     ERT_SSL_KEY:
    ```

## Uploading the pipeline and running it.

```
cd ci
fly -t local set-pipeline -p pcf-aws-prepare -c pcfaws_terraform_pipeline.yml --load-vars-from pcfaws_terraform_params.yml
fly -t local unpause-pipeline -p pcf-aws-prepare
```


## Testing terraform changes

This is an approach to testing the terraform changes locally before committing the changes back.
Create a [tfvars](https://www.terraform.io/intro/getting-started/variables.html#from-a-file) file with the list of the variables required for the terraform script, and has a format along these lines:
```
aws_access_key = "*******"
aws_secret_key = "*******"
opsman_ami = "ami-d0b4d0c6"
amis_nat = "ami-303b1458"
aws_region = "us-east-1"
az1 = "us-east-1a"
az2 = "us-east-1b"
az3 = "us-east-1d"
```

This can be created using the parameters file for the pipeline by searching for the lines with `TF_VAR_` prefix, removing the `TF_VAR_` prefix and formatting the rest of the content in the above form.

Then run `terraform plan` with this var file and grep for the expected results.

For eg. when adding an environment prefix to say the IAM policy name `PcfErtPolicy`, a sample test would be along these lines:

```
terraform plan -var-file=TF_VARS.txt | grep PcfErtPolicy | grep myenv
echo $? # check for exit code, 0 is good, 1 is bad
```
