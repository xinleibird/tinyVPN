#!/bin/sh

server=$(uci get tinyvpn.@tinyvpn[-1].server 2>/dev/null)
port=$(uci get tinyvpn.@tinyvpn[-1].port 2>/dev/null)
password=$(uci get tinyvpn.@tinyvpn[-1].password 2>/dev/null)
fec=$(uci get tinyvpn.@tinyvpn[-1].fec 2>/dev/null)
intf=$(uci get tinyvpn.@tinyvpn[-1].intf 2>/dev/null)
net=$(uci get tinyvpn.@tinyvpn[-1].net 2>/dev/null)
route_file=$(uci get tinyvpn.@tinyvpn[-1].route_file 2>/dev/null)
pidfile=$(uci get tinyvpn.@tinyvpn[-1].pidfile 2>/dev/null)
route_mode=$(uci get tinyvpn.@tinyvpn[-1].route_mode 2>/dev/null)

PID=$(cat "$pidfile" 2>/dev/null)

/usr/bin/tinyvpn -c -r"$server":"$port" -f"$fec" -k "$password" --sub-net "$net" --tun-dev "$intf" --keep-reconnect &
loger() {
  echo "$(date '+%c') up.$1 tinyvpn[$PID] $2"
}

# Get original gateway
gateway=$(ip route show 0/0 | sed -e 's/.* via \([^ ]*\).*/\1/')
loger info "The default gateway: via $gateway"

# Turn on NAT over VPN
iptables -t nat -A POSTROUTING -o "$intf" -j MASQUERADE
iptables -I FORWARD 1 -i "$intf" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD 1 -o "$intf" -j ACCEPT
loger notice "Turn on NAT over $intf"

# Change routing table
suf="dev $intf"

ip route add "$server" via "$gateway"
# 全局0,国内1,国外2
# 国内指首先全局走隧道,然后chnroute表中的走普通国内路由
# 国外指不设定全局隧道,然后chnroute表中的走普通国内路由(此时是回国)

if [ "$route_mode" != 2 ]; then
  ip route add 0.0.0.0/1 dev "$intf"
  ip route add 128.0.0.0/1 dev "$intf"
  loger notice "Default route changed to VPN tun"
  suf="via $gateway"
fi

# Load global rules
suf="via $gateway"
if [ "$route_mode" != 0 -a -f "$route_file" ]; then
  grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}" "$route_file" >/tmp/tinyvpn
  sed -e "s/^/route add /" -e "s/$/ $suf/" /tmp/tinyvpn | ip -batch -
  loger notice "Route rules have been loaded"
fi

loger info "Script $0 completed"
