#!/bin/sh

server=$(uci get tinyvpn.@tinyvpn[-1].server 2>/dev/null)
intf=$(uci get tinyvpn.@tinyvpn[-1].intf 2>/dev/null)
pidfile=$(uci get tinyvpn.@tinyvpn[-1].pidfile 2>/dev/null)
route_mode=$(uci get tinyvpn.@tinyvpn[-1].route_mode 2>/dev/null)

PID=$(cat "$pidfile" 2>/dev/null)
loger() {
  echo "$(date '+%c') down.$1 tinyvpn[$PID] $2"
}
killall tinyvpn

# Turn off NAT over VPN
iptables -t nat -D POSTROUTING -o "$intf" -j MASQUERADE
iptables -D FORWARD -i "$intf" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -D FORWARD -o "$intf" -j ACCEPT
loger notice "Turn off NAT over $intf"

# 全局0,国内1,国外2
# 国内指首先全局走隧道,然后chnroute表中的走普通国内路由
# 国外指不设定全局隧道,然后chnroute表中的走普通国内路由(此时是回国)
ip route del "$server"
if [ "$route_mode" != 2 ]; then
  ip route del 0.0.0.0/1
  ip route del 128.0.0.0/1
  loger notice "Default route changed to original route"
fi

# Remove route rules
if [ -f /tmp/tinyvpn ]; then
  sed -e "s/^/route del /" /tmp/tinyvpn | ip -batch -
  loger notice "Route rules have been removed"
fi

rm -rf /tmp/tinyvpn

loger info "Script $0 completed"
