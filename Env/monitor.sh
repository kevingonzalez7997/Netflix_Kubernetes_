#!/bin/bash
############################## PROMETHEUS #########################################################
sudo apt update
# Variables for easier updating
PROMETHEUS_VERSION="2.47.1"
PROMETHEUS_URL="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

# Check if Prometheus user exists
if id "prometheus" &>/dev/null; then
    echo "Prometheus user already exists. Skipping user creation."
else
    sudo useradd --system --no-create-home --shell /bin/false prometheus
fi

# Download and Extract Prometheus
wget "${PROMETHEUS_URL}"
tar -xvf "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

# Move files to appropriate locations
sudo mkdir -p /data /etc/prometheus
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/prometheus.yml

sudo mv prometheus.service /etc/systemd/system/

# Set ownership
sudo chown -R prometheus:prometheus /etc/prometheus/ /data/

sudo mv prometheus.service /etc/systemd/system/

sudo systemctl enable prometheus
sudo systemctl start prometheus
##################################### NODE EXPORTER ##########################################################
sudo useradd --system --no-create-home --shell /bin/false node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz

tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter*

sudo mv node_exporter.service /etc/systemd/system/

sudo systemctl enable node_exporter
sudo systemctl start node_exporter
######################################## GRAFANA #############################################################

sudo apt-get update
sudo apt-get install -y apt-transport-https software-properties-common

wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

sudo apt-get update
sudo apt-get -y install grafana

sudo systemctl enable grafana-server

sudo systemctl start grafana-server