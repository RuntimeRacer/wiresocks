#!/bin/sh

# deploy.sh 1 51820 2 10.13.13.0 socks4://host.docker.internal:48501 tun0 198.18.0.1

# Get CLI Args
DEPLOYMENT_ID=$1
WG_UDP_PORT=$2
WG_PEERS=$3
WG_SUBNET_IP=$4
PROXY_ADDRESS=$5
TUN_ID=$6
TUN_SUBNET_IP=$7

# Init env file based on args
rm .env
cp .env.example .env

# Replace lines in .env file
sed -i "s,.*DEPLOYMENT_ID.*,DEPLOYMENT_ID=${DEPLOYMENT_ID}," .env
sed -i "s,.*WG_UDP_PORT.*,WG_UDP_PORT=${WG_UDP_PORT}," .env
sed -i "s,.*WG_PEERS.*,WG_PEERS=${WG_PEERS}," .env
sed -i "s,.*WG_SUBNET_IP.*,WG_SUBNET_IP=${WG_SUBNET_IP}," .env
sed -i "s,.*PROXY_ADDRESS.*,PROXY_ADDRESS=${PROXY_ADDRESS}," .env
sed -i "s,.*TUN_ID.*,TUN_ID=${TUN_ID}," .env
sed -i "s,.*TUN_SUBNET_IP.*,TUN_SUBNET_IP=${TUN_SUBNET_IP}," .env

# build local wiresocks container image with own tweaks
docker build -t wiresocks-multi-tunnel .

# Start services
docker-compose -p "multi-tunnel-${DEPLOYMENT_ID}" up -d