squid tproxy
============

Scripts for setting up fully layer 2 transparent squid proxying. 
See http://wiki.squid-cache.org/Features/Tproxy4


Network Setup
=============

Network Topology
----------------

TODO: Document here


Example config files
--------------------

### /etc/network/interfaces
    TODO: [Robert, please insert copy of /etc/network/interfaces as an example

Script Setup
============

Dependencies
------------
ebtables, iptables, sh, iproute2, gawk, redis, python-nflog, python-dpkt

Config Files
------------

Edit `config.sh` to reflect the interfaces above


Running
=======

Start `./daemon.py`
