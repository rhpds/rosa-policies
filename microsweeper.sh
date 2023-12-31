#!/bin/bash
# ---------------------------------------------------------
# Set up permissions for the MicroSweeper Lab
#
# Available variables passed from workload ocp4_workload_rosa_policies:
# - POLICIES_DIR: Temporary directory for policy files
# - GUID: Unique identifier of the environment
# - AWS_USER_NAME: AWS user name for the student
# - AWS_ACCOUNT_ID: AWS account id for the student
# - OIDC_ENDPOINT: OIDC Endpoint
# ---------------------------------------------------------

# ---------------------------------------------------------
# Set up User permissions to create a table
# ---------------------------------------------------------

cat <<EOF > ${POLICIES_DIR}/user-create-table-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "dynamodb:CreateTable",
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy \
  --policy-name UserCreateTablePolicy \
  --policy-document file://${POLICIES_DIR}/user-create-table-policy.json

aws iam attach-user-policy \
  --user-name ${AWS_USER_NAME} \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/UserCreateTablePolicy

# ---------------------------------------------------------
# Set up Service Account Permissions
# ---------------------------------------------------------
cat <<EOF > ${POLICIES_DIR}/role-dynamodb-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_ENDPOINT}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_ENDPOINT}:sub": "system:serviceaccount:microsweeper-ex:microsweeper"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name irsa-${GUID} \
  --assume-role-policy-document file://${POLICIES_DIR}/role-dynamodb-trust-policy.json \
  --description "IRSA Role (${GUID})"

aws iam attach-role-policy \
  --role-name irsa-${GUID} \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

# ---------------------------------------------------------
# Cleanup
# ---------------------------------------------------------

# rm ${POLICIES_DIR}/user-create-table-policy.json
# rm ${POLICIES_DIR}/role-dynamodb-trust-policy.json
