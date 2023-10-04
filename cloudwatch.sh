#!/bin/bash
# ---------------------------------------------------------
# Set up permissions for the Cloudwatch Lab
#
# Available variables passed from workload ocp4_workload_rosa_policies:
# - POLICIES_DIR: Temporary directory for policy files
# - GUID: Unique identifier of the environment
# - AWS_USER_NAME: AWS user name for the student
# - AWS_ACCOUNT_ID: AWS account id for the student
# - OIDC_ENDPOINT: OIDC Endpoint
# ---------------------------------------------------------

# ---------------------------------------------------------
# Get current AWS region
# ---------------------------------------------------------
AWS_REGION=$(aws configure get region)

# ---------------------------------------------------------
# Set up User permissions to Describe Log Groups
# ---------------------------------------------------------

cat <<EOF > ${POLICIES_DIR}/user-describe-log-groups-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:DescribeLogGroups",
            "Resource": "arn:aws:logs:${AWS_REGION}:${AWS_ACCOUNT_ID}:*"
        }
    ]
}
EOF

aws iam create-policy \
  --policy-name UserDescribeLogGroupsPolicy \
  --policy-document file://${POLICIES_DIR}/user-describe-log-groups-policy.json

aws iam attach-user-policy \
  --user-name ${AWS_USER_NAME} \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/UserDescribeLogGroupsPolicy

# ---------------------------------------------------------
# Set up Permissions for CloudWatch
# ---------------------------------------------------------

cat << EOF > ${POLICIES_DIR}/cloudwatch-policy.json
{
"Version": "2012-10-17",
"Statement": [
   {
         "Effect": "Allow",
         "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:PutRetentionPolicy"
         ],
         "Resource": "arn:aws:logs:*:*:*"
   }
]
}
EOF

aws iam create-policy \
  --policy-name RosaCloudWatch-${GUID} \
  --policy-document file://${POLICIES_DIR}/cloudwatch-policy.json

# ---------------------------------------------------------
# Set up Cloudwatch trust policy and role to use that policy
# ---------------------------------------------------------

cat <<EOF > ${POLICIES_DIR}/role-cloudwatch-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
    "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_ENDPOINT}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "${OIDC_ENDPOINT}:sub": "system:serviceaccount:openshift-logging:logcollector"
      }
    }
  }]
}
EOF

aws iam create-role \
  --role-name RosaCloudWatch-${GUID} \
  --assume-role-policy-document file://${POLICIES_DIR}/role-cloudwatch-trust-policy.json \
  --description "Cloud Watch Role (${GUID})" \
  --tags "Key=rosa-workshop,Value=true"

aws iam attach-role-policy \
  --role-name RosaCloudWatch-${GUID} \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/RosaCloudWatch-${GUID}

# ---------------------------------------------------------
# Cleanup
# ---------------------------------------------------------

# rm ${POLICIES_DIR}/user-describe-log-groups-policy.json
# rm ${POLICIES_DIR}/cloudwatch-policy.json
# rm ${POLICIES_DIR}/role-cloudwatch-trust-policy.json
