# Users
resource "aws_iam_user" "pcf_iam_user" {
    name = "${var.prefix}_pcf_iam_user"
    path = "/system/"
}
resource "aws_iam_access_key" "pcf_iam_user_access_key" {
    user = "${aws_iam_user.pcf_iam_user.name}"
}
resource "aws_iam_user_policy_attachment" "PcfAdminPolicy_role_attach" {
    user = "${aws_iam_user.pcf_iam_user.name}"
    policy_arn = "${aws_iam_policy.PcfAdminPolicy.arn}"
}

#Roles

resource "aws_iam_role" "pcf_admin_role" {
    name = "${var.prefix}_pcf_admin_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "PcfAdminRolePolicy"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "PcfAdminPolicy_role_attach" {
    role = "${aws_iam_role.pcf_admin_role.name}"
    policy_arn = "${aws_iam_policy.PcfAdminPolicy.arn}"
}
resource "aws_iam_instance_profile" "pcf_admin_role_instance_profile" {
    name = "${var.prefix}_pcf_admin_role_instance_profile"
    role = "${aws_iam_role.pcf_admin_role.name}"
}


# Policies
resource "aws_iam_user_policy" "PcfErtPolicy" {
    name = "${var.prefix}_PcfErtPolicy"
    user = "${aws_iam_user.pcf_iam_user.name}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::${var.prefix}-buildpacks",
                "arn:aws:s3:::${var.prefix}-buildpacks/*",
                "arn:aws:s3:::${var.prefix}-droplets",
                "arn:aws:s3:::${var.prefix}-droplets/*",
                "arn:aws:s3:::${var.prefix}-packages",
                "arn:aws:s3:::${var.prefix}-packages/*",
                "arn:aws:s3:::${var.prefix}-resources",
                "arn:aws:s3:::${var.prefix}-resources/*"
            ],
            "Effect": "Allow",
            "Sid": "ElasticRuntimeS3Permissions"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "PcfAdminPolicy" {
    name = "${var.prefix}_PcfAdminPolicy"
    path = "/"
    description = "${var.prefix} PCF Admin Policy"
    policy = "${data.aws_iam_policy_document.pcf_iam_rds_role_policy_document.json}"
}

# Policy Document
data "aws_iam_policy_document" "pcf_iam_rds_role_policy_document" {
    policy_id = "${var.prefix}_IamRdsRolePolicyDocument"
    statement {
            actions = [
                "iam:Add*",
                "iam:Attach*",
                "iam:ChangePassword",
                "iam:Create*",
                "iam:DeactivateMFADevice",
                "iam:Delete*",
                "iam:Detach*",
                "iam:EnableMFADevice",
                "iam:GenerateCredentialReport",
                "iam:GenerateServiceLastAccessedDetails",
                "iam:GetAccessKeyLastUsed",
                "iam:GetAccountAuthorizationDetails",
                "iam:GetAccountPasswordPolicy",
                "iam:GetAccountSummary",
                "iam:GetContextKeysForCustomPolicy",
                "iam:GetContextKeysForPrincipalPolicy",
                "iam:GetCredentialReport",
                "iam:GetGroup",
                "iam:GetGroupPolicy",
                "iam:GetLoginProfile",
                "iam:GetOpenIDConnectProvider",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:GetSAMLProvider",
                "iam:GetSSHPublicKey",
                "iam:GetServerCertificate",
                "iam:GetServiceLastAccessedDetails",
                "iam:GetUser",
                "iam:GetUserPolicy",
                "iam:List*",
                "iam:Put*",
                "iam:RemoveClientIDFromOpenIDConnectProvider",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:RemoveUserFromGroup",
                "iam:ResyncMFADevice",
                "iam:SetDefaultPolicyVersion",
                "iam:SimulateCustomPolicy",
                "iam:SimulatePrincipalPolicy",
                "iam:Update*"
            ]
            resources = [
                "*"
            ],
            effect = "Deny"
            sid = "PcfAdminIamPermissions"
    }
    statement {
            actions = [
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:AssociateAddress",
                "ec2:DisassociateAddress",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeImages",
                "ec2:CopyImage",
                "ec2:DescribeInstances",
                "ec2:RunInstances",
                "ec2:RebootInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeKeypairs",
                "ec2:DescribeRegions",
                "ec2:DescribeSnapshots",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:CreateTags",
                "ec2:DescribeVolumes",
                "ec2:CreateVolume",
                "ec2:AttachVolume",
                "ec2:DeleteVolume",
                "ec2:DetachVolume"
            ],
            resources = [
                "*"
            ],
            effect = "Allow",
            sid = "PcfAdminEc2Permissions"
    }
    statement {
        actions = [
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
        ],
        resources = [
            "*"
        ],
        effect = "Allow",
        sid = "PcfAdminElbPermissions"
    },
    statement = {
        actions = [
                "s3:*"
            ],
        resources = [
                "arn:aws:s3:::${var.prefix}-bosh",
                "arn:aws:s3:::${var.prefix}-bosh/*",
        ],
        effect = "Allow",
        sid = "PcfAdminS3Permissions"
     }
     statement = {
         actions = [
                "iam:PassRole"
            ],
            resources = [
                "${aws_iam_role.pcf_admin_role.arn}"
            ],
            effect = "Allow",
            sid = "AllowToCreateInstanceWithCurrentInstanceProfile"
     }
    statement = {
        actions = [
            "iam:GetInstanceProfile"
        ],
        resources = [
                "${aws_iam_instance_profile.pcf_admin_role_instance_profile.arn}"
        ],
        effect = "Allow",
        sid = "AllowToGetInfoAboutCurrentInstanceProfile"
     }
}
