# AWS Ops Manager Upgrade

## Notes:
- this pipeline uses `cliaas` to drive the rotation of the ops manager VM. This tool assumes that the targeted ops manager VM has an associated Elastic IP. If you do not have one assigned to the ops manager VM this pipeline will fail.
