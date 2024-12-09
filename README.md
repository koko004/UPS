# UPS stack

# Stack NUT+PeaNUT

<h1><p align="center">
<img alt="NUT" src="https://networkupstools.org/images/nut-logo.png"> + 
<img alt="PeaNUT" src="https://raw.githubusercontent.com/Brandawg93/PeaNUT/main/src/app/icon.svg" width="60px">
</p></h1>

<p align="center"><img src="https://raw.githubusercontent.com/Brandawg93/PeaNUT/main/images/charts.png" width="600px" /></p>

## Docker compose
```yaml
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
      - PORT=http://192.168.1.255:80
      - SECRET=yoursecret
      - SERIAL=
      - SERVER=master
      - USER=nut
      - VENDORID=
    ports:
      - "3493:3493"
    network_mode: host
    restart: always
  peanut:
    image: brandawg93/peanut:latest
    container_name: PeaNUT
    restart: unless-stopped
    volumes:
      - /root/peaNUT/config:/config
    ports:
      - 8080:8080
    environment:
      - WEB_PORT=8080
```
# NUT

<p align="center">
    <img alt="NUT" src="https://networkupstools.org/images/nut-logo.png">
</p>

## docker compose
```yaml
version: '3.3'
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
      - PORT=http://192.168.1.255:80
      - SECRET=yoursecret
      - SERIAL=
      - SERVER=master
      - USER=nut
      - VENDORID=
    ports:
      - "3493:3493"
    network_mode: host
    restart: always
```

<p align="center">
    <img alt="PeaNUT" src="https://raw.githubusercontent.com/Brandawg93/PeaNUT/main/src/app/icon.svg" width="200px">
</p>

# PeaNUT

A Tiny Dashboard for Network UPS Tools

[![PayPal](https://img.shields.io/badge/paypal-donate-blue?logo=paypal)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=CEYYGVB7ZZ764&item_name=peanut&currency_code=USD&source=url)
![Docker Pulls](https://img.shields.io/docker/pulls/brandawg93/peanut)
[![Crowdin](https://badges.crowdin.net/nut-dashboard/localized.svg)](https://crowdin.com/project/nut-dashboard)

<img src="https://raw.githubusercontent.com/Brandawg93/PeaNUT/main/images/charts.png" width="600px" />

## Installation

Install using Docker

### docker run

```bash
docker run -v ${PWD}/config:/config -p 8080:8080 --restart unless-stopped \
--env WEB_PORT=8080 brandawg93/peanut
```

### docker-compose.yml (network connection)

```yaml
services:
  peanut:
    image: brandawg93/peanut:latest
    container_name: PeaNUT
    restart: unless-stopped
    volumes:
      - /root/peaNUT/config:/config
    ports:
      - 8080:8080
    environment:
      - WEB_PORT=8080
```
