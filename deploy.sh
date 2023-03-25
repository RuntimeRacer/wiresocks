#!/bin/sh

# deploy.sh server.name.or.ip 51820 10.13.13.0 3 socks4://host.docker.internal:48501,socks4://host.docker.internal:48502 198.0.0.1

# Get CLI Args
# Wireguard basics
WG_HOST=$1 # IP of host server
WG_UDP_PORT=$2
WG_SUBNET_IP=$3
# Proxy related
PROXY_PEERS=$5 # amount of peers per proxy
PROXIES=$6 # comma-separated string of proxies

# Some calculations
PROXY_COUNT=$(echo "$PROXIES"  | tr -cd , | wc -c)
PROXY_COUNT=$(($PROXY_COUNT + 1))
WG_PEERS=$(($PROXY_COUNT * $PROXY_PEERS))

# Init env file based on args
rm .env
cp .env.example .env

# Replace lines in .env file
sed -i "s,.*WG_HOST.*,WG_HOST=${WG_HOST}," .env
sed -i "s,.*WG_UDP_PORT.*,WG_UDP_PORT=${WG_UDP_PORT}," .env
sed -i "s,.*WG_PEERS.*,WG_PEERS=${WG_PEERS}," .env
sed -i "s,.*WG_SUBNET_IP.*,WG_SUBNET_IP=${WG_SUBNET_IP}," .env
sed -i "s,.*PROXY_PEERS.*,PROXY_PEERS=${PROXY_PEERS}," .env
sed -i "s|.*PROXIES.*|PROXIES=${PROXIES}|" .env

# Create a backup of this deployment's env file in case we redeploy with wrong settings by mistake
cp .env ".env.bak.$(date +"%Y_%m_%d_%H_%M_%S")"

# build local wiresocks container image with own tweaks
docker build -t wiresocks-multi-tunnel .

# Start services
docker-compose -p "multi-tunnel" up -d