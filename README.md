# CI/CD DevSecOps Pipeline

This guide provides instructions for setting up a CI/CD pipeline integrated with security tools for a DevSecOps approach. Follow these steps to install and configure Trivy, OWASP ZAP (headless mode), SonarQube, and Checkov on an Ubuntu EC2 server.

## Prerequisites
Ensure the following are set up in your environment:
- **Docker** installed.
- **Python 3-venv** installed.

## Tools Overview
1. **Trivy**: A vulnerability scanner for containers and other artifacts.
2. **SonarQube**: A platform for code quality analysis, run through Docker.(Static testing)
3. **OWASP ZAP**: A security tool for application testing, used in headless mode. (Dynamic testing)
4. **Checkov**: A static analysis tool for Terraform configurations.

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
2. **Output Storage**: Ensure that Trivy scan outputs are saved in a `reports` directory of your CI/CD pipeline workspace (e.g., /var/lib/jenkins_home/workspace/<your-pipeline-name>/reports/**trivy_report.json**).
   
### 2. SonarQube
SonarQube is used for static code analysis

1. **SonarQube Installation with Docker**: SonarQube will be run in a Docker container and integrated with Jenkins.
   ```bash
   docker run -d --name sonarqube -p 9000:9000 sonarqube:latest
   ```

### 3. OWASP ZAP
OWASP ZAP helps with dynamic security testing for web applications

1. **OWASP ZAP**: Install OWASP ZAP in headless mode for scanning web applications.

```bash
wget https://github.com/zaproxy/zaproxy/releases/download/v2.14.0/ZAP_2_14_0_unix.sh -O zap_install.sh
chmod +x zap_install.sh
sudo ./zap_install.sh -q -dir /opt/zap
```  

2. **Output Storage**: Ensure that OWASP ZAP scan results are saved in the `reports` directory of your pipeline workspace (e.g., /var/lib/jenkins_home/workspace/<your-pipeline-name>/reports/**zap_scan_results.json**).

### 4. Checkov
Checkov is used for static analysis of Terraform configurations.

1. **Python Env**: Create a Python Virtual Environment

2. **Checkov**: Install Checkov in the Python Env

3. **Output Storage**: Ensure that Checkov scan outputs are saved in the reports directory of your pipeline workspace (e.g., /var/lib/jenkins_home/workspace/<your-pipeline-name>/reports/**checkov_report.json**).
