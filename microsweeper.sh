#!/bin/bash
cat <<EOF > ${HOME}/trust-policy.json
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
  --assume-role-policy-document file://${HOME}/trust-policy.json \
  --description "IRSA Role (${GUID})"

aws iam attach-role-policy \
  --role-name irsa-${GUID} \
  --policy-arn=arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

