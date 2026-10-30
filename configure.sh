#!/usr/bin/env bash
# Usage: ./configure.sh <dockerhub_username> <your_email>
# Fills in your Docker Hub username and email in Jenkinsfile + docker-compose.yml
set -e
if [ $# -ne 2 ]; then
  echo "Usage: ./configure.sh <dockerhub_username> <your_email>"
  exit 1
fi
DH="$1"; MAIL="$2"
sed -i "s/YOUR_DOCKERHUB_USER/${DH}/g; s/YOUR_EMAIL/${MAIL}/g" Jenkinsfile
sed -i "s/santhoshkiran/${DH}/g" docker-compose.yml
echo "Done. Jenkinsfile and docker-compose.yml now use: ${DH} / ${MAIL}"
