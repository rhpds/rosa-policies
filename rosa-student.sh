#!/bin/bash
# ---------------------------------------------------------
# Set up permissions for student user
#
# Available variables passed from workload ocp4_workload_rosa_policies:
# - POLICIES_DIR: Temporary directory for policy files
# - GUID: Unique identifier of the environment
# - AWS_USER_NAME: AWS user name for the student
# - AWS_ACCOUNT_ID: AWS account id for the student
# - OIDC_ENDPOINT: OIDC Endpoint
# ---------------------------------------------------------

cat << EOF > ${POLICIES_DIR}/user-iam-policy.json
{
    "Version": "2012-10-17",
    "Statement": [ {
        "Effect": "Allow",
        "Action": [
            "iam:List*",
            "iam:Get*"
        ],
        "Resource": "*"
    } ]
}
EOF

aws iam create-policy \
  --policy-name RosaStudentIAM \
  --policy-document file:///${POLICIES_DIR}/user-iam-policy.json

aws iam attach-user-policy \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/RosaStudentIAM \
  --user-name ${AWS_USER_NAME}

# ---------------------------------------------------------
# Cleanup
# ---------------------------------------------------------
# rm -f ${POLICIES_DIR}/user-iam-policy.json
