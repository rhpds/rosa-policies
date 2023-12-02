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

# Remove sshd config file preventing login with password
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf

# Setup rbash
cp /bin/bash /bin/rbash

# Set up bin directory
mkdir ${USER_HOME}/bin
chmod 0700 ${USER_HOME}/bin

# Change the user's shell to use rbash
usermod -s /bin/rbash rosa

# All commands that rosa user should have from /usr/bin
bin_commands=('watch' 'date' 'clear' 'cat' 'echo' 'jq' 'cut' 'grep' 'base64' 'less' 'nslookup' 'head' 'ab' 'curl' 'sleep')
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

chown rosa:users ${USER_HOME}/.bashrc
chown -R rosa:users ${USER_HOME}/*

# Make .bashrc immutable
chattr +i ${USER_HOME}/.bashrc
