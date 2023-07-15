#!/bin/bash

# Author: Austin Hunt
# Date: 12 July 2023
# Version: 1.0

# Purpose of the script:
# Build a Zeek Docker image and start the Zeek container

# Usage:
# Step 1: Make the script executable (chmod +x start_zeek_docker.sh).
# Step 2: Run the script (./start_zeek_docker.sh)

# You can edit these values
TAG_NAME='my_zeek_image'
CONTAINER_NAME='my_zeek_container'
NETWORK_NAME='host' # This has to be a docker network that exists. Its best to leave is as host, unless you know you need to change it.
VOLUME_NAME='my_zeek_volume'
# This ZEEK_HOME_DIR needs to match what is in the Dockerfile
ZEEK_HOME_DIR='/usr/local/zeek/'
ZEEK_LOGS_PATH='spool/zeek/'

# Find the mirror interface that Zeek should listen on. We do this by looking for an interface with no IPv4 address.
mirror_interface=$(ip --brief a | grep -v "\." | cut -d " " -f 1)

# Set the mirror interface in the Dockerfile
sed -Ei "s/ARG\sZEEK_LISTEN_INTERFACE=/ARG ZEEK_LISTEN_INTERFACE=$mirror_interface/" ./Dockerfile

# Don't touch anything after these lines unless you know what you are doing
sudo docker build --tag $TAG_NAME - < Dockerfile
sudo docker run --detach --restart unless-stopped --name $CONTAINER_NAME --network $NETWORK_NAME --volume $VOLUME_NAME:$ZEEK_HOME_DIR$ZEEK_LOGS_PATH $TAG_NAME
echo "Zeek logs are located at /var/lib/docker/volumes/$VOLUME_NAME/_data/"

# Useful Docker commands
# Stop all docker containers......................................sudo docker stop $(sudo docker container ls -q)
# List all docker containers......................................sudo docker container ls -a
# Remove all docker containers....................................sudo docker container rm -f $(sudo docker container ls -a -q)
# Remove all docker images........................................sudo docker image rmi -f $(sudo docker image ls -a -q)
# Remove all docker volumes.......................................sudo docker volume rm -f $(sudo docker volume ls -q)
# Remove all docker networks......................................sudo docker network rm $(sudo docker network ls -q)
# Show docker container logs......................................sudo docker logs -f <container_name>
# Connect to a running container..................................sudo docker exec -i -t <container_name> /bin/bash
# Remove all unused containers, networks, images, and volumes.....sudo docker system prune --all --volumes --force
