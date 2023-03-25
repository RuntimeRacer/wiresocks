#!/bin/sh

# deploy.sh 1 server.name.or.ip 51820 2 10.13.13.0 socks4://host.docker.internal:48501 tun0 198.18.0.1

# Get CLI Args
DEPLOYMENT_ID=$1
WG_HOST=$2
WG_UDP_PORT=$3
WG_PEERS=$4
WG_SUBNET_IP=$5
PROXY1_ADDRESS=$6
PROXY2_ADDRESS=$7
TUN_ID=$8
TUN_SUBNET_IP=$9

# Init env file based on args
rm .env
cp .env.example .env

# Replace lines in .env file
sed -i "s,.*DEPLOYMENT_ID.*,DEPLOYMENT_ID=${DEPLOYMENT_ID}," .env
sed -i "s,.*WG_HOST.*,WG_HOST=${WG_HOST}," .env
sed -i "s,.*WG_UDP_PORT.*,WG_UDP_PORT=${WG_UDP_PORT}," .env
sed -i "s,.*WG_PEERS.*,WG_PEERS=${WG_PEERS}," .env
sed -i "s,.*WG_SUBNET_IP.*,WG_SUBNET_IP=${WG_SUBNET_IP}," .env
sed -i "s,.*PROXY1_ADDRESS.*,PROXY1_ADDRESS=${PROXY1_ADDRESS}," .env
sed -i "s,.*PROXY2_ADDRESS.*,PROXY2_ADDRESS=${PROXY2_ADDRESS}," .env
sed -i "s,.*TUN_ID.*,TUN_ID=${TUN_ID}," .env
sed -i "s,.*TUN_SUBNET_IP.*,TUN_SUBNET_IP=${TUN_SUBNET_IP}," .env

# build local wiresocks container image with own tweaks
docker build -t wiresocks-multi-tunnel .

# Start services
docker-compose -p "multi-tunnel-${DEPLOYMENT_ID}" up -d