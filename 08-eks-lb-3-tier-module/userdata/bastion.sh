#!/bin/bash
# Bastion Host User Data Script

yum update -y
yum install -y amazon-linux-extras
amazon-linux-extras install -y epel
yum install -y \
    curl \
    wget \
    git \
    jq \
    python3 \
    python3-pip \
    unzip \
    bind-utils \
    telnet

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# Create scripts directory
mkdir -p /home/ec2-user/scripts
chown ec2-user:ec2-user /home/ec2-user/scripts

# Configure motd
cat > /etc/motd << EOF
###############################################################
#                   EKS Bastion Host                         #
# Three-Tier Architecture Deployment                        #
# Cluster: ${cluster_name}                                  #
# Region: ${region}                                         #
###############################################################
EOF

echo "Bastion host setup completed successfully!"