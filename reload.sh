#!/bin/sh

# This reloads the services if the env vars or .env file changed, see:
# https://stackoverflow.com/questions/42149529/how-to-reload-environment-variables-in-docker-compose-container-with-minimum-dow
docker-compose -p "multi-tunnel" up -d