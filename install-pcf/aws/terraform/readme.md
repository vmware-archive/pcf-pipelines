
***Note:*** While you can run `terraform apply` to deploy the resources, this terraform scripts are meant to be run as part of concourse pipeline.
### Run `terraform apply`
### Following Environment variables should be set in the shell
* aws_access_key_id=`YOUR_AWS_ACCESS_KEY`
* aws_secret_access_key=`YOUR_AWS_SECERT_KEY`
* aws_key_name=`AWS_KEY_NAME`
* aws_cert_urn=`AWS_CERT_URN`
* rds_db_username=`rds db username`
* rds_db_password=`rds db password`
* environment=`environment name`

## variables.tf
* set environment
* All the variables are defined
* cidr for vpc and subnets
* availability zone definitions
* amis for NAT instance

## s3.tf
* create as3 buckets

## iam.tf
* Create User, Roles, policies

## vpc.tf
* create vpc
* create subnets
* create routing tables

## security_group.tf
* create security groups

## load_balancers.tf
* create load balancers

## load_balancers_security_group.tf
* create security groups for load balancers 

## rds.tf
* create mysql database