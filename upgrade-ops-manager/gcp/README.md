**Known Issue**

If you are using the v23 release of pcf-pipelines and you are upgrading Ops Manager to 2.0.x, there is an issue whereby the new Ops Manager disk size defaults to 5GB, and likely to cause the upgrade to fail.  Use v23.1+, or manually bump the disk size to avoid this issue. 
