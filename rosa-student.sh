#!/bin/bash
cat << EOF > ${POLICIES_DIR}/student-user-policy-iam.json
{
    "Version": "2012-10-17",
    "Statement": [ {
        "Effect": "Allow",
        "Action": [
            "iam:List*"
        ],
        "Resource": "*"
    } ]
}
EOF

aws iam create-policy --policy-name "RosaStudentIAM" \
  --policy-document file:///${POLICIES_DIR}/student-user-policy-iam.json \
  --query Policy.Arn \
  --output text

# rm -f ${POLICIES_DIR}/student-user-policy-iam.json

aws iam attach-user-policy \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/RosaStudentIAM \
  --user-name ${AWS_USER_NAME}

