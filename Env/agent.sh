#!/bin/bash
############################## DOCKER ##############################################
sudo apt update

sudo apt install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add the user to the docker group and activate changes without logging out
sudo usermod -aG docker ubuntu

newgrp docker
############################## SONARQUBE #################################################
# Update package list
sudo apt update

# Install OpenJDK 11
sudo apt install -y openjdk-11-jdk

# Install unzip utility
sudo apt install -y unzip

# Download SonarQube
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.9.2.46101.zip

# Unzip SonarQube
sudo unzip sonarqube-8.9.2.46101.zip -d /opt

# Rename the SonarQube directory
sudo mv /opt/sonarqube-8.9.2.46101 /opt/sonarqube

# Create a symbolic link
sudo ln -s /opt/sonarqube/bin/linux-x86-64/sonar.sh /usr/local/bin/sonar

# Create a new system user for SonarQube
sudo useradd -r sonarqube

# Set permissions
sudo chown -R sonarqube:sonarqube /opt/sonarqube

# Configure SonarQube to run as a service
sudo tee /etc/systemd/system/sonar.service << EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Start SonarQube service
sudo systemctl start sonar

# Enable SonarQube service to start on boot
sudo systemctl enable sonar
############################ TRIVY ##############################################
#Trivy scanner install 
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy       
############################## AGENT PREREQ #######################
sudo apt install -y openjdk-11-jre
