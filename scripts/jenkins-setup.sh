#!/bin/bash

# Jenkins Setup Script for Vincent's Portfolio CI/CD
# This script installs and configures Jenkins with necessary tools

set -e

# Variables from Terraform
JENKINS_USER="${jenkins_admin_username}"
AZURE_CLIENT_ID="${azure_client_id}"
AZURE_CLIENT_SECRET="${azure_client_secret}"
AZURE_TENANT_ID="${azure_tenant_id}"
AZURE_SUBSCRIPTION_ID="${azure_subscription_id}"
ACR_LOGIN_SERVER="${acr_login_server}"
RESOURCE_GROUP_NAME="${resource_group_name}"
AKS_CLUSTER_NAME="${aks_cluster_name}"

# Update system
apt-get update -y

# Install required packages
apt-get install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip

# Install Java (required for Jenkins)
apt-get install -y openjdk-11-jdk

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Add Jenkins user to docker group
usermod -aG docker $JENKINS_USER

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y
apt-get install -y jenkins

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Terraform
TERRAFORM_VERSION="1.13.4"
wget https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
mv terraform /usr/local/bin/
rm terraform_$${TERRAFORM_VERSION}_linux_amd64.zip

# Configure Azure CLI with service principal
mkdir -p /var/lib/jenkins/.azure
cat > /var/lib/jenkins/.azure/credentials << EOF
[default]
client_id = $AZURE_CLIENT_ID
secret = $AZURE_CLIENT_SECRET
tenant = $AZURE_TENANT_ID
EOF

# Create Azure login script
cat > /var/lib/jenkins/azure-login.sh << 'EOF'
#!/bin/bash
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

az account set --subscription $AZURE_SUBSCRIPTION_ID
EOF

# Make scripts executable and set ownership
chmod +x /var/lib/jenkins/azure-login.sh
chown -R jenkins:jenkins /var/lib/jenkins/.azure
chown jenkins:jenkins /var/lib/jenkins/azure-login.sh

# Start and enable Jenkins
systemctl start jenkins
systemctl enable jenkins

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Create Jenkins initial configuration directory
mkdir -p /var/lib/jenkins/init.groovy.d

# Create Jenkins initial admin user setup script
cat > /var/lib/jenkins/init.groovy.d/01-create-admin-user.groovy << 'EOF'
#!groovy

import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def adminUsername = System.getenv('JENKINS_ADMIN_USER') ?: 'admin'
def adminPassword = System.getenv('JENKINS_ADMIN_PASSWORD') ?: 'admin123'

hudsonRealm.createAccount(adminUsername, adminPassword)
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Disable CLI over remoting
instance.getDescriptor("jenkins.CLI").get().setEnabled(false)

// Enable Agent to Master Access Control
Jenkins.instance.injector.getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

instance.save()
EOF

# Install Jenkins plugins
cat > /var/lib/jenkins/plugins.txt << 'EOF'
ant:latest
antisamy-markup-formatter:latest
build-timeout:latest
cloudbees-folder:latest
configuration-as-code:latest
credentials-binding:latest
email-ext:latest
git:latest
github-branch-source:latest
gradle:latest
ldap:latest
mailer:latest
matrix-auth:latest
pam-auth:latest
pipeline-github-lib:latest
pipeline-stage-view:latest
ssh-slaves:latest
timestamper:latest
workflow-aggregator:latest
ws-cleanup:latest
docker-workflow:latest
kubernetes:latest
azure-cli:latest
azure-credentials:latest
blueocean:latest
EOF

# Set environment variables for Jenkins
cat > /etc/default/jenkins << EOF
NAME=jenkins
USER=\$NAME
DAEMON_ARGS="--name=\$NAME --inherit --verbosegc --pidfile=\$PIDFILE --checkUpgrade --webroot=/var/cache/\$NAME/war --logfile=/var/log/\$NAME/\$NAME.log"

JAVA_ARGS="-Djava.awt.headless=true"
JENKINS_ARGS="--webroot=/var/cache/\$NAME/war --httpPort=\$HTTP_PORT"

# Azure environment variables
export AZURE_CLIENT_ID="$AZURE_CLIENT_ID"
export AZURE_CLIENT_SECRET="$AZURE_CLIENT_SECRET"
export AZURE_TENANT_ID="$AZURE_TENANT_ID"
export AZURE_SUBSCRIPTION_ID="$AZURE_SUBSCRIPTION_ID"
export ACR_LOGIN_SERVER="$ACR_LOGIN_SERVER"
export RESOURCE_GROUP_NAME="$RESOURCE_GROUP_NAME"
export AKS_CLUSTER_NAME="$AKS_CLUSTER_NAME"
EOF

# Create Jenkins Configuration as Code file
mkdir -p /var/lib/jenkins/jenkins.yaml.d
cat > /var/lib/jenkins/jenkins.yaml.d/jenkins.yaml << 'EOF'
jenkins:
  systemMessage: "Vincent's Portfolio CI/CD Server"
  numExecutors: 2
  scmCheckoutRetryCount: 3
  mode: NORMAL

  securityRealm:
    local:
      allowsSignup: false
      users:
       - id: "admin"
         password: "admin123"

  authorizationStrategy:
    globalMatrix:
      permissions:
        - "Overall/Administer:admin"
        - "Overall/Read:authenticated"

  globalNodeProperties:
    - envVars:
        env:
          - key: "AZURE_CLIENT_ID"
            value: "${azure_client_id}"
          - key: "AZURE_TENANT_ID"
            value: "${azure_tenant_id}"
          - key: "ACR_LOGIN_SERVER"
            value: "${acr_login_server}"
          - key: "RESOURCE_GROUP_NAME"
            value: "${resource_group_name}"
          - key: "AKS_CLUSTER_NAME"
            value: "${aks_cluster_name}"

unclassified:
  location:
    url: "http://jenkins-server:8080/"
    adminAddress: "vincent@example.com"

tool:
  git:
    installations:
    - name: "Default"
      home: "git"

  dockerTool:
    installations:
    - name: "Docker"
      home: "/usr/bin/docker"
EOF

# Set proper permissions
chown -R jenkins:jenkins /var/lib/jenkins
chmod -R 755 /var/lib/jenkins

# Create systemd override for Jenkins to set environment variables
mkdir -p /etc/systemd/system/jenkins.service.d
cat > /etc/systemd/system/jenkins.service.d/override.conf << EOF
[Service]
Environment="AZURE_CLIENT_ID=$AZURE_CLIENT_ID"
Environment="AZURE_CLIENT_SECRET=$AZURE_CLIENT_SECRET"
Environment="AZURE_TENANT_ID=$AZURE_TENANT_ID"
Environment="AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID"
Environment="ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER"
Environment="RESOURCE_GROUP_NAME=$RESOURCE_GROUP_NAME"
Environment="AKS_CLUSTER_NAME=$AKS_CLUSTER_NAME"
Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/jenkins.yaml.d/"
EOF

# Reload systemd and restart Jenkins
systemctl daemon-reload
systemctl restart jenkins

# Wait for Jenkins to start
sleep 30

# Configure kubectl for the jenkins user
sudo -u jenkins mkdir -p /var/lib/jenkins/.kube

# Create a script to get AKS credentials
cat > /var/lib/jenkins/get-aks-credentials.sh << EOF
#!/bin/bash
source /var/lib/jenkins/azure-login.sh
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --file /var/lib/jenkins/.kube/config --overwrite-existing
EOF

chmod +x /var/lib/jenkins/get-aks-credentials.sh
chown jenkins:jenkins /var/lib/jenkins/get-aks-credentials.sh

# Execute the script to get initial AKS credentials
sudo -u jenkins /var/lib/jenkins/get-aks-credentials.sh

echo "Jenkins setup completed successfully!"
echo "Jenkins URL: http://$(curl -s ifconfig.me):8080"
echo "Default admin credentials: admin / admin123"
echo "Please change the default password after first login."