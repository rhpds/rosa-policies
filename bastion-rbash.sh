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

USER_HOME=/home/rosa
AWS_REGION=$(/usr/local/bin/aws configure get region)

# Setup rbash
cp /bin/bash /bin/rbash

# Set up bin directory
mkdir ${USER_HOME}/bin
chmod 0700 ${USER_HOME}/bin

# Change the user's shell to use rbash
usermod -s /bin/rbash rosa

# All commands that rosa user should have from /usr/bin
bin_commands=('watch' 'date' 'ls' 'clear' 'cat' 'rm' 'echo' 'git' 'jq')
for command in "${bin_commands[@]}"; do
  ln -sf /usr/bin/${command} ${USER_HOME}/bin/${command}
done

# All commands that rosa user should have from /usr/local/bin
local_bin_commands=('oc' 'rosa' 'aws')
for command in "${local_bin_commands[@]}"; do
  ln -sf /usr/local/bin/${command} ${USER_HOME}/bin/${command}
done

# Set up .bashrc
cat <<EOF > ${USER_HOME}/.bashrc
# .bashrc

export GUID=${GUID}

readonly PATH=${USER_HOME}/bin
export PATH
EOF

# Make .bashrc immutable
chattr +i ${USER_HOME}/.bashrc

# Create files for labs
cat <<EOF > ${USER_HOME}/application.properties
# AWS DynamoDB configurations
dynamodb.table=microsweeper-scores-${GUID}
dynamodb.aws.credentials.type=default

# OpenShift configurations
openshift.service-account=microsweeper
kubernetes-client.trust-certs=true
EOF

cat <<EOF > ${USER_HOME}/deployment.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: microsweeper-appservice
spec:
  replicas: 1
  selector:
    matchLabels:
      deployment: microsweeper-appservice
  template:
    metadata:
      labels:
        deployment: microsweeper-appservice
    spec:
      containers:
      - name: microsweeper-appservice
        serviceAccountName: microsweeper
        env:
        - name: AWS_REGION
          value: ${AWS_REGION}
        image: quay.io/rhpds/microsweeper:1.0.0
        imagePullPolicy: IfNotPresent        
        ports:
        - containerPort: 8080
          protocol: TCP
        volumeMounts:
        - mountPath: /deployments/app/application.properties
          name: application-properties
          subPath: application.properties
      volumes:
      - name: application-properties
        configMap:
          defaultMode: 420
          name: microsweeper
EOF

chown -R rosa:users ${USER_HOME}
