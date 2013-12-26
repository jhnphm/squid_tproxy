#! /bin/sh

. ./config.py

BRIDGE_MAC=$(ip link show ${BRIDGE_IFACE}|awk '/link/ {print $2}')

# Log all DHCP replies to nflog for handling by script
# Pass stuff to broadcast through and don't log
ebtables -t filter -A FORWARD -i $INET_IFACE -p ipv4 --ip-destination 255.255.255.255 -j ACCEPT
ebtables -t filter -A FORWARD -i $INET_IFACE -p ipv4 --ip-proto udp --ip-dport 68 --nflog-prefix DHCPREPLY --nflog-group 1

# Create chain for adding mac address rewriting rules
ebtables -t nat -N TPROXY_MACADDR_FIX -P RETURN
ebtables -t nat -A POSTROUTING -o $INET_IFACE -s $BRIDGE_MAC -p ipv4 -ip-proto tcp --ip-dport 80 -j TPROXY_MACADDR_FIX

