#! /bin/sh

# This program is free software; you can redistribute it and/or modify it under
# the terms of the gnu general public license as published by the free software
# foundation; either version 2 of the license, or (at your option) any later
# version

. ./config.py

BRIDGE_MAC=$(ip link show ${BRIDGE_IFACE}|awk '/link/ {print $2}')
BRIDGE_ADDR=$(ip addr show ${BRIDGE_IFACE}|awk '/inet / {print $2}'|awk -F / '{print $1}')

# Log all DHCP replies to nflog for handling by script
# Pass stuff to broadcast through and don't log
ebtables -t filter -A FORWARD -i $INET_IFACE -p ipv4 --ip-destination 255.255.255.255 -j ACCEPT
ebtables -t filter -A FORWARD -i $INET_IFACE -p ipv4 --ip-proto udp --ip-dport 68 --nflog-prefix DHCPREPLY --nflog-group 1

# Create chain for adding mac address rewriting rules
ebtables -t nat -N TPROXY_MACADDR_FIX -P DROP
ebtables -t nat -A POSTROUTING -o $CLIENT_IFACE -j ACCEPT
ebtables -t nat -A POSTROUTING -o $INET_IFACE -s $BRIDGE_MAC -p ipv4 --ip-src $BRIDGE_ADDR -j ACCEPT
ebtables -t nat -A POSTROUTING -o $INET_IFACE -s $BRIDGE_MAC -p ipv4 --ip-proto tcp --ip-dport 80 -j TPROXY_MACADDR_FIX


