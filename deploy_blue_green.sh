#!/bin/bash

#
# This script updates a running docker-compose blue/green configuration.
# It first pulls down the new docker image from DockerHub (or whatever image
# repository one would like to use).
# It then redirects all the traffic to green, kills blue, relaunches it with
# the new Docker Image.
#
# At that point, things start to get interesting: the script will hold until
# the health checks passes on blue. If it doesn't after 1 minute, the script
# exists with an error code and green is not updated.
# This way, we can make sure that we keep one running, valid version of our
# code whatever happens. When a new image gets deployed, if it's valid, it will
# start on blue.
#
# Eventually, if blue starts well then greens gets updated but we don't wait
# for it's health check to be complete. HAProxy makes it so that no traffic
# will be redirected to it while it's still unhealthy.
#
# Maintainer: Étienne Lafarge <etienne.lafarge@gmail.com>
#

if [[ -z "$DOCKER_IMAGE" ]]; then
  echo "Building local images delcared in your docker-compose.yaml..."
  /usr/bin/docker-compose build
else
  echo "Pulling down the latest version of the Docker image from DockerHub..."
  /usr/bin/docker pull "$DOCKER_IMAGE"
fi

# Let's disable the blue container
echo "Shutting down blue and waiting for it to process its requests"

echo "disable server dockers/dockerblue" | socat tcp4-connect:localhost:4691 stdio
sleep 5s # Arbitrary value to leave green enough time to reply to pending
         # requests. Actually there should be a mechanism somewhere in HAProxy
         # that redirects to green a request that would fail on blue at that
         # point. TODO: investigate that a little

# Then stop and remove it with docker-compose
/usr/bin/docker-compose stop docker-blue || echo "No blue container to stop"
/usr/bin/docker-compose rm -f docker-blue

# And start another one with the new version of the code
echo "Starting blue with the newly pulled image..."
/usr/bin/docker-compose up --no-recreate -d
echo "enable server dockers/dockerblue" | socat tcp4-connect:localhost:4691 stdio

# Wait for our status check(s) to be confirmed (times out after 30 seconds)
# TODO: understand what HAProxy gives us a bit better and take the most
# relevant indicator into account
HAPROXY_STATE=$(echo "show servers state dockers" | socat tcp4-connect:localhost:4691 stdio | grep dockerblue)
NOTUPYET_REGEX='^[0-9]+ dockers [0-9]+ dockerblue [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} 2 [0-9]+ [0-9]+ [0-9]+ [0-9]+ [0-9]+ [0-9]+ 4 [0-9]+ [0-9]+ [0-9]+ [0-9]+$'

timeout_date=$(date +"%Y%m%d%H%M%S" -d "+30seconds")
while ! [[ $HAPROXY_STATE =~ $NOTUPYET_REGEX ]]
do
  # Do we need to time out ?
  now=$(date +"%Y%m%d%H%M%S")
  if [[ "$now" -gt "$timeout_date" ]]; then
    echo "[ERROR] HAProxy's health check on blue container failed !"
    echo "[INFO]  Green container won't be updated... please fix the Docker image and redeploy :)"
    exit 12
  fi

  # No ? Well let's wait a bit more then!
  echo "Waiting for blue to be ready & healthy..."
  sleep 1s
  HAPROXY_STATE=$(echo "show servers state dockers" | socat tcp4-connect:localhost:4691 stdio | grep dockerblue)
done

# Let's renable blue
echo "Blue is ready to run the new Docker image, let's update green now !"

# To finally re-launch green with its latest version (without status check, it
# should work if it did for blue)
echo "disable server dockers/dockergreen" | socat tcp4-connect:localhost:4691 stdio

/usr/bin/docker-compose stop docker-green
/usr/bin/docker-compose rm -f docker-green
/usr/bin/docker-compose up --no-recreate -d
echo "enable server dockers/dockergreen" | socat tcp4-connect:localhost:4691 stdio

# That's all :)
