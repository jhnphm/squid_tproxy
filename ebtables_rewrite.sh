#! /bin/sh

# this program is free software; you can redistribute it and/or modify it under
# the terms of the gnu general public license as published by the free software
# foundation; either version 2 of the license, or (at your option) any later
# version. 

. ./config.sh

# Log all DHCP replies to nflog for handling by script
# Pass stuff to broadcast through and don't log
ebtables -t filter -A FORWARD -i $INET_IFACE -p ipv4 --ip-destination 255.255.255.255 -j ACCEPT
ebtables -t filter -A FORWARD -i $INET_IFACE -p ipv4 --ip-proto udp --ip-dport 68 --nflog-prefix DHCPREPLY --nflog-group 1

ebtables -t nat -N TPROXY_MACADDR_FIX -P RETURN
ebtables -t nat -A POSTROUTING -o $INET_IFACE -j TPROXY_MACADDR_FIX

