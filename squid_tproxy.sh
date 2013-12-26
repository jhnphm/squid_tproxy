#! /bin/sh

. ./config.py

# Send all marked packets to interface that has squid listening
# In this case, localhost (loopback), could be any interface squid is listening on though
ip -f inet rule add fwmark 1 table 100
ip -f inet route add local default dev ${LOCAL_IFACE} table 100

# Setup a chain DIVERT to mark packets 
iptables -t mangle -N DIVERT
iptables -t mangle -A DIVERT -j MARK --set-mark 1
iptables -t mangle -A DIVERT -j ACCEPT

# Use DIVERT to prevent existing connections going through TPROXY twice: 
iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT

# Mark all other (new) packets and use TPROXY to pass into Squid:
iptables -t mangle -A PREROUTING -p tcp --dport 80 -j TPROXY --tproxy-mark 0x1/0x1 --on-port 3129

# Change MAC target address to local bridge
# Then drop all ethernet frames that are being TPROXIED so that they don't pass onto internet and become redundant
ebtables -t broute -A BROUTING \
        -i $CLIENT_IFACE -p ipv4 --ip-proto tcp --ip-dport 80 \
        -j redirect --redirect-target DROP

ebtables -t broute -A BROUTING \
        -i $INET_IFACE -p ipv4 --ip-proto tcp --ip-sport 80 \
        -j redirect --redirect-target DROP

