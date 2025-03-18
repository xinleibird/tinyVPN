#!/bin/sh

# Turn on IP forwarding
sysctl -w net.ipv4.ip_forward=1

PATH=/sbin:/usr/sbin:/bin:/usr/bin
NAME=tinyvpn            # Introduce the short server's name here
DAEMON=/usr/bin/tinyvpn # Introduce the server's location here

LISTEN_ADDR="0.0.0.0"
LISTEN_PORT="50150"
MASK="kSf[8I8Ep2D]n4"
FEC="20:10"
SUBNET="10.22.22.0"
TUN_NAME="tun100"

[ -x "$DAEMON" ] || exit 0

# Server configuration file
CONF="-s -l$LISTEN_ADDR:$LISTEN_PORT -f$FEC -k $MASK --sub-net ${SUBNET}  --tun-dev $TUN_NAME"

$DAEMON "$CONF"

# turn on NAT over VPN
if ! (iptables-save -t nat | grep -q $NAME); then
  iptables -t nat -A POSTROUTING -s $SUBNET/16 ! -d $SUBNET/16 -m comment --comment $NAME -j MASQUERADE
fi
iptables -A FORWARD -s $SUBNET/16 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -d $SUBNET/16 -j ACCEPT

# Turn on MSS fix (MSS = MTU - TCP header - IP header)
iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

echo "$0" "done"
