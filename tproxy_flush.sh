#! /bin/sh

# This program is free software; you can redistribute it and/or modify it under
# the terms of the gnu general public license as published by the free software
# foundation; either version 2 of the license, or (at your option) any later
# version

. ./config.py

# Flush existing iptables mangle table and routing rules
iptables -t filter -F 
iptables -t filter -X CP_FILTER
iptables -t mangle -F 
iptables -t mangle -X DIVERT

# Delete route rules
ip -f inet rule del fwmark 1 table 100
ip -f inet route del local default dev ${LOCAL_IFACE} table 100


# Remove existing ebtables rules in broute if they exist
ebtables -t broute -F
ebtables -t nat -F
ebtables -t nat -X TPROXY_MACADDR_FIX
ebtables -t filter -F
