#!/bin/bash
# Exécuté une seule fois au premier démarrage de la machine
set -euxo pipefail

apt-get update -y
apt-get install -y docker.io git
systemctl enable --now docker

cd /opt
git clone --depth 1 https://github.com/maroua94/projet-cloudrssp.git
cd projet-cloudrssp/portail
docker build -t portail .
docker run -d --name portail --restart unless-stopped -p 80:80 portail
