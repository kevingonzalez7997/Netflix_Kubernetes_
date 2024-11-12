
# CI/CD DevSecOps Pipeline

This guide provides instructions for setting up a CI/CD pipeline integrated with security tools for a DevSecOps approach. 
Follow these steps to install and configure Trivy, OWASP ZAP (headless mode), SonarQube, and Checkov on an Ubuntu EC2 server.

## Prerequisites
Ensure the following are set up in your environment:
- **Docker** installed.
- **Python 3-venv** installed.

---

## Tools Overview

For each tool, write a brief explanation covering the following:
- What the tool does.
- Why you are using it in the CI/CD pipeline.

1. **Trivy**: A vulnerability scanner for containers and other artifacts.
2. **SonarQube**: A platform for code quality analysis, run through Docker (static testing).
3. **OWASP ZAP**: A security tool for application testing, used in headless mode (dynamic testing).
4. **Checkov**: A static analysis tool for Terraform configurations.

---

## Installation and Configuration

### 1. Trivy Installation
Trivy is a vulnerability scanner for containers and other artifacts.

1. **Install Trivy** by following the [official installation documentation](https://aquasecurity.github.io/trivy/v0.18.3/installation/):
   ```bash
   sudo apt-get install wget apt-transport-https gnupg lsb-release
   wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
   echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
   sudo apt-get update
   sudo apt-get install trivy
   ```
2. **Output Storage**: Ensure that [Trivy scan](https://aquasecurity.github.io/trivy/v0.18.3/) outputs are saved in a `reports` directory of your CI/CD pipeline workspace (e.g., `/var/lib/jenkins_home/workspace/<your-pipeline-name>/reports/**trivy_report.json**`).

---

### 2. SonarQube Setup for Static Code Analysis
SonarQube is used for static code analysis to improve code quality and security.

#### Part 1: SonarQube Installation with Docker
1. **Run SonarQube in Docker**:
   ```bash
   docker run -d --name sonarqube -p 9000:9000 sonarqube:latest
   ```

2. **Access SonarQube**:
   - In your browser, go to `http://<your-ec2-public-ip>:9000`.
   - **Default Credentials**:
     - **Username**: `admin`
     - **Password**: `admin`
   - Change the default password upon your first login.

#### Part 2: Generate a SonarQube Token for Jenkins Integration
1. **Generate a SonarQube Token**:
   - In SonarQube, navigate to **Administration > Security > Users**.
   - Select your user (likely **admin**) and go to the **Tokens** tab.
   - Click **Generate Token**.
   - Name the token (e.g., `JenkinsToken`).
   - Copy the token—you’ll use it in Jenkins shortly.

#### Part 3: Integrate SonarQube with Jenkins
1. **Install SonarQube Scanner Plugin in Jenkins**:
   - Open Jenkins and go to **Manage Jenkins > Manage Plugins**.
   - In the **Available** tab, search for **SonarQube Scanner** and install it.
   - Restart Jenkins if prompted.

2. **Add SonarQube Server in Jenkins**:
   - Go to **Manage Jenkins > Configure System**.
   - Scroll down to **SonarQube servers**.
   - Click **Add SonarQube** and fill in the details:
     - **Name**: Enter a descriptive name, like `SonarQubeServer`.
     - **Server URL**: Enter `http://<your-ec2-public-ip>:9000`.
     - **Server Authentication Token**: Click **Add** to create a new secret text credential.
       - **Kind**: Secret text
       - **Secret**: Paste the SonarQube token you created earlier.
       - **ID**: Enter a unique ID, such as `sonar-token`.

3. **Configure SonarQube Scanner in Jenkins**:
   - Go to **Manage Jenkins > Global Tool Configuration**.
   - Scroll down to **SonarQube Scanner**.
   - Click **Add SonarQube Scanner** and provide a name, such as `SonarScanner`.
   - Check **Install automatically** and choose the default version.

---

### 3. OWASP ZAP Setup for Dynamic Security Testing
OWASP ZAP helps with dynamic security testing for web applications. **It must be run in headless mode** to enable seamless integration into the CI/CD pipeline without a graphical interface.

1. **Install OWASP ZAP** in **headless mode** for scanning web applications.
   ```bash
   wget https://github.com/zaproxy/zaproxy/releases/download/v2.15.0/ZAP_2_15_0_unix.sh -O zap_install.sh
   chmod +x zap_install.sh
   sudo ./zap_install.sh -q -dir /opt/zap
   ```

2. **Output Storage**: Ensure that OWASP ZAP scan results are saved in the `reports` directory of your pipeline workspace (e.g., `/var/lib/jenkins_home/workspace/<your-pipeline-name>/reports/**zap_scan_results.json**`).

---

### 4. Checkov Setup for Static Analysis of Terraform Configurations
Checkov is used for static analysis of Terraform configurations to identify security misconfigurations.

1. **Set up Python Environment**:
   - Create a Python virtual environment for Checkov.

2. **Install Checkov**:
   - Install Checkov within the virtual environment.

3. **Output Storage**: Ensure that Checkov scan outputs are saved in the `reports` directory of your pipeline workspace (e.g., `/var/lib/jenkins_home/workspace/<your-pipeline-name>/reports/**checkov_report.json**`).
