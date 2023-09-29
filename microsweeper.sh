#!/bin/bash
cat <<EOF > ${POLICIES_DIR}/trust-policy.json
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
  --assume-role-policy-document file://${POLICIES_DIR}/trust-policy.json \
  --description "IRSA Role (${GUID})"

#rm ${POLICIES_DIR}/trust-policy.json

aws iam attach-role-policy \
  --role-name irsa-${GUID} \
  --policy-arn=arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

