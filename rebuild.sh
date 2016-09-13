#!/bin/bash

docker-compose kill

# Remove the images
# -v : Remove any anonymous volumes attached to containers
docker-compose rm -v --force

# Rebuild the main Dockerfile
docker build --tag aegir/hostmaster --file dockerfiles/Dockerfile dockerfiles
# Rebuild the local Dockerfile
docker build --tag aegir/hostmaster:local --file dockerfiles/Dockerfile-local dockerfiles

# Remove the sites/aegir.local.computer (required to get it to install again)
rm -rf aegir-home/hostmaster-7.x-3.x/sites/aegir.local.computer

# Up the containers
docker-compose up -d

echo "Start logging. Press CTRL-C to stop watching"
docker-compose logs -f
