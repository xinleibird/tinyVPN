#!/bin/sh

mkdir /etc/tinyvpn

cp ./client_up.sh /etc/tinyvpn
cp ./client_down.sh /etc/tinyvpn
cp ./tinyvpn.conf /etc/config/tinyvpn
cp ./tinyvpn /etc/init.d/tinyvpn

chmod +x /etc/tinyvpn/client_up.sh
chmod +x /etc/tinyvpn/client_down.sh
chmod +x /etc/init.d/tinyvpn
