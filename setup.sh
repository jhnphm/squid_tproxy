#! /bin/sh

# This program is free software; you can redistribute it and/or modify it under
# the terms of the gnu general public license as published by the free software
# foundation; either version 2 of the license, or (at your option) any later
# version

. ./config.py

# Allow packet forwarding, disable reverse path filtering
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.default.rp_filter=0
sysctl -w net.ipv4.conf.all.rp_filter=0
y
# Disable bridge-nf, just use ebtables
sysctl -w net.bridge.bridge-nf-call-iptables=0
sysctl -w net.bridge.bridge-nf-call-arptables=0
sysctl -w net.bridge.bridge-nf-call-ip6tables=0
sysctl -w net.bridge.bridge-nf-call-iptables=0
sysctl -w net.bridge.bridge-nf-filter-pppoe-tagged=0
sysctl -w net.bridge.bridge-nf-filter-vlan-tagged=0

