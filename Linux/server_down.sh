#!/bin/sh

# Turn off IP forwarding
# sysctl -w net.ipv4.ip_forward=0

PATH=/sbin:/usr/sbin:/bin:/usr/bin
NAME=tinyvpn            # Introduce the short server's name here
DAEMON=/usr/bin/tinyvpn # Introduce the server's location here

SUBNET="10.22.22.0"

[ -x "$DAEMON" ] || exit 0

killall tinyvpn

# Turn off NAT over VPN
iptables -t nat -D POSTROUTING -s $SUBNET/16 ! -d $SUBNET/16 -m comment --comment $NAME -j MASQUERADE
iptables -D FORWARD -s $SUBNET/16 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -D FORWARD -d $SUBNET/16 -j ACCEPT

# Turn off MSS fix (MSS = MTU - TCP header - IP header)
iptables -t mangle -D FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

echo "$0" "done"
