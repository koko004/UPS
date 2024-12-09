#!/bin/bash

# Colors
YELLOW='\033[1;33m'
NC='\033[0m'

# ASCII Art Title
echo -e "${YELLOW}"
echo "    _   ____  ________   __  ______  _____    _____                     "
echo "   / | / / / / /_  __/  / / / / __ \/ ___/   / ___/_________  ____  ___ "
echo "  /  |/ / / / / / /    / / / / /_/ /\__ \    \__ \/ ___/ __ \/ __ \/ _ \\"
echo " / /|  / /_/ / / /    / /_/ / ____/___/ /   ___/ / /__/ /_/ / /_/ /  __/"
echo "/_/ |_/\____/ /_/     \____/_/    /____/   /____/\___/\____/ .___/\___/ "
echo "                                                          /_/           "
echo -e "${NC}"

# Menu Options
echo "Welcome to NUT UPS Scope Installer"
echo "1. Install NUT + PeaNUT + Prometheus + Grafana"
echo "2. Install NUT + PeaNUT"
echo "3. Recreate Grafana Dashboard"
echo "4. Exit"
read -p "Choose an option [1-4]: " option

# Function to install prerequisites
install_prerequisites() {
    echo "Installing prerequisites..."
    apt-get update
    apt-get install -y git wget nano curl docker docker-compose
    echo "Prerequisites installed."
}

# Function to create Grafana Dashboard
recreate_grafana_dashboard() {
    echo "Recreating Grafana Dashboard..."
    rm /root/grafana/dashboards/main-dashboard.json
    cd /root/grafana/dashboards
    wget https://raw.githubusercontent.com/koko004/UPS/refs/heads/main/dashboard/main-dashboard.json
    echo "Grafana Dashboard recreated successfully."
}

# Function to create configuration files
create_configuration_files() {
    echo "Creating configuration files..."

    # PeaNUT config
    mkdir -p /root/peaNUT/config
    cat > /root/peaNUT/config/settings.yml <<EOL
NUT_SERVERS:
  - HOST: nut
    PORT: 3493
    USERNAME: ''
    PASSWORD: ''
INFLUX_HOST: ''
INFLUX_TOKEN: ''
INFLUX_ORG: ''
INFLUX_BUCKET: ''
INFLUX_INTERVAL: 10
EOL

    # Prometheus config
    mkdir -p /root/prometheus
    cat > /root/prometheus/prometheus.yml <<EOL
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'nut-exporter'
    honor_timestamps: true
    scrape_interval: 30s
    scrape_timeout: 10s
    metrics_path: /metrics
    scheme: http
    follow_redirects: true
    enable_http2: true
    static_configs:
      # NUT server address
      - targets: ['nut:3493']
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: nut-exporter:9995
EOL
    # Grafana config datasources
    mkdir -p /root/grafana/datasources
    cat > /root/grafana/datasources/datasource.yml <<EOL
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    isDefault: true
    # Access mode - proxy (server in the UI) or direct (browser in the UI).
    url: http://prometheus:9090
    jsonData:
      httpMethod: POST
      manageAlerts: true
      prometheusType: Prometheus
      prometheusVersion: 2.44.0
      cacheLevel: 'High'
      disableRecordingRules: false
      incrementalQueryOverlapWindow: 10m
      exemplarTraceIdDestinations:
        # Field with internal link pointing to data source in Grafana.
        # datasourceUid value can be anything, but it should be unique across all defined data source uids.
        - datasourceUid: my_jaeger_uid
          name: traceID
EOL
    # Grafana config settings dashboards 
    mkdir -p /root/grafana/dashboards
    cat > /root/grafana/dashboard.yaml <<EOL
apiVersion: 1

providers:
  - name: "Dashboard provider"
    orgId: 1
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: false
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: true
EOL
    # Grafana config settings dashboards 
    wget https://raw.githubusercontent.com/koko004/UPS/refs/heads/main/dashboard/main-dashboard.json
    mv main-dashboard.json /root/grafana/dashboards
    echo "Configuration files created."

    echo "Creating configuration files..."
    recreate_grafana_dashboard
    echo "Configuration files created."
}

# Function to create and start Docker Compose
setup_docker_compose() {
    echo "Setting up Docker Compose..."

    # Docker Compose configuration
    cat > docker-compose.yml <<EOL
version: '3.9'
services:
  nut-upsd:
    container_name: nut
    image: instantlinux/nut-upsd
    environment:
      - TZ=Europe/Madrid
      - API_USER=master
      - API_PASSWORD=yourpassword
      - DRIVER=netxml-ups
      - GROUP=nut
      - MAXAGE=
      - NAME=UPS
      - POLLINTERVAL=
      - PORT=http://192.168.1.254:80
      - SECRET=yoursecret
      - SERIAL=
      - SERVER=master
      - USER=nut
      - VENDORID=
    ports:
      - 3493:3493
    restart: always
  peanut:
    image: brandawg93/peanut:latest
    container_name: PeaNUT
    restart: always
    volumes:
      - /root/peaNUT/config:/config
    ports:
      - 8080:8080
    environment:
      - WEB_PORT=8080
  nut-exporter:
    image: hon95/prometheus-nut-exporter:1
    container_name: nut-exporter
    environment:
      - TZ=Europe/Madrid
      - HTTP_PATH=/metrics
    ports:
      - "9995:9995"
    depends_on:
      - nut-upsd
    restart: always
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    ports:
      - '9090:9090'
    volumes:
      - /root/prometheus:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    restart: always
  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - '3000:3000'
    depends_on:
      - prometheus
    volumes:
      - /root/grafana/dashboard.yaml:/etc/grafana/provisioning/dashboards/main.yaml
      - /root/grafana/dashboards:/var/lib/grafana/dashboards
      - /root/grafana/datasources/datasource.yml:/etc/grafana/provisioning/datasources/datasource.yml
      - /root/grafana/datasources:/etc/grafana/provisioning/datasources
    environment:
      - GF_LOG_LEVEL=debug
      - GF_INSTALL_PLUGINS=grafana-simple-json-datasource
    restart: always
EOL

    # Start Docker Compose
    docker-compose -f docker-compose.yml -p nut-ups-scope up -d
    echo "NUT UPS Scope is up and running."
}

# Handle menu selection
case $option in
    1)
        install_prerequisites
        create_configuration_files
        setup_docker_compose
        ;;
    2)
        install_prerequisites
        create_configuration_files
        echo "Skipping Prometheus and Grafana setup."
        ;;
    3)
        recreate_grafana_dashboard
        ;;
    4)
        echo "Exiting. Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac
