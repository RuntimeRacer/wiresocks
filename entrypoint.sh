#!/bin/sh

# Modified version of 
# https://github.com/xjasonlyu/tun2socks/blob/main/docker/entrypoint.sh

TUN1="${TUN1:-tun1}"
TUN2="${TUN2:-tun2}"
ADDR1="${ADDR1:-198.18.0.1}"
ADDR1="${ADDR2:-198.20.0.1}"
LOGLEVEL="${LOGLEVEL:-info}"
#WG_SUBNET_IP="${WG_SUBNET_IP:-10.13.13.0}"

create_tun() {
  # TUN 1
  ip tuntap add mode tun dev "$TUN1"
  ip addr add "${ADDR1}/15" dev "$TUN1"
  ip link set dev "$TUN1" up

  # TUN 2
  ip tuntap add mode tun dev "$TUN2"
  ip addr add "${ADDR2}/15" dev "$TUN2"
  ip link set dev "$TUN2" up
}

config_route() {
  if [ "$TUN_INCLUDED_ROUTES" == "0.0.0.0/0" ]; then
    # Proxy 1
    ip route add default via "$ADDR1" dev "$TUN1" table 101
    ip rule add from 10.13.13.2 table 101
    # Proxy 2
    ip route add default via "$ADDR2" dev "$TUN2" table 102
    ip rule add from 10.13.13.3 table 102
#  else
#    for addr in $(echo "$TUN_INCLUDED_ROUTES" | tr ',' '\n'); do
#      ip route add $addr dev $TUN
#    done
  fi
}


run() {

  create_tun
  config_route

  # execute extra commands
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

  # Proxy 1
  exec tun2socks --loglevel "$LOGLEVEL" --device "$TUN1" --proxy "$PROXY1" $ARGS &
  # Proxy 1
  exec tun2socks --loglevel "$LOGLEVEL" --device "$TUN2" --proxy "$PROXY2" $ARGS &

  # Wait for processes to finish (they should usually not finish except they're breaking)
  wait

}

run || exit 1