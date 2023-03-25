#!/bin/sh

# Modified version of 
# https://github.com/xjasonlyu/tun2socks/blob/main/docker/entrypoint.sh

LOGLEVEL="${LOGLEVEL:-info}"
TUN_IDX=0 # TUN starts with 0
IP_TABLE_IDX=100 # IP Tables start with 100
PEER_IDX=2 # Peer Starts with .2/32; sequential loop will
PROXY_PEERS=${PROXY_PEERS:-3}

create_tun() {
  tun_name=$1
  tun_range_ip=$2

  # Setup TUN
  ip tuntap add mode tun dev "$tun_name"
  ip addr add "$tun_range_ip/15" dev "$tun_name"
  ip link set dev "$tun_name" up
}

config_route() {
    tun_name=$1
    tun_range_ip=$2
    ip_table_name=$3

    # Proxy 1
    ip route add default via "$tun_range_ip" dev "$tun_name" table "$ip_table_name"

    # For each peer
    i=0
    while [ $i -lt "$PROXY_PEERS" ]
    do
      last_part=$((PEER_IDX + i))
      ip rule add from "10.13.13.$last_part" table "$ip_table_name"
      true $(( i++ ))
    done
    # inc index
    PEER_IDX=$((PEER_IDX + PROXY_PEERS))
}

setup() {
  default_args=$1
  for proxy in $(echo "$PROXIES" | tr ',' '\n'); do
    # calculations
    ip_range=$((TUN_IDX * 2))

    # determine vars
    tun_name="tun$TUN_IDX"
    tun_range_ip="198.$ip_range.0.1"

    # setup
    create_tun $tun_name $tun_range_ip
    config_route $tun_name $tun_range_ip $IP_TABLE_IDX

    # Start tun2socks
    exec tun2socks --loglevel "$LOGLEVEL" --device "$tun_name" --proxy "$proxy" "$default_args" &

    # inc indexes
    TUN_IDX=$((TUN_IDX + 1))
    IP_TABLE_IDX=$((IP_TABLE_IDX + 1))
  done
}

run() {
  # apply extra commands
  if [ -n "$EXTRA_COMMANDS" ]; then
    sh -c "$EXTRA_COMMANDS"
  fi

  if [ -n "$MTU" ]; then
    ARGS="--mtu $MTU"
  fi

  if [ -n "$RESTAPI" ]; then
    ARGS="$ARGS --restapi $RESTAPI"
  fi

  if [ -n "$UDP_TIMEOUT" ]; then
    ARGS="$ARGS --udp-timeout $UDP_TIMEOUT"
  fi

  if [ -n "$TCP_SNDBUF" ]; then
    ARGS="$ARGS --tcp-sndbuf $TCP_SNDBUF"
  fi

  if [ -n "$TCP_RCVBUF" ]; then
    ARGS="$ARGS --tcp-rcvbuf $TCP_RCVBUF"
  fi

  if [ "$TCP_AUTO_TUNING" = 1 ]; then
    ARGS="$ARGS --tcp-auto-tuning"
  fi

  # Set up the routing
  setup "$ARGS"

  # Wait for processes to finish (they should usually not finish except they're breaking)
  wait

}

run || exit 1