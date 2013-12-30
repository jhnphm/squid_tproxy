#! /usr/bin/python

# This program is free software; you can redistribute it and/or modify it under
# the terms of the gnu general public license as published by the free software
# foundation; either version 2 of the license, or (at your option) any later
# version. 

# external non-python core dependencies
from dpkt import dpkt,ip,udp,dhcp
import redis
import nflog

from socket import AF_BRIDGE, AF_INET, AF_INET6, inet_ntoa, ntohs


import array
import config
import os
import re
import struct 
import subprocess
import tempfile
import time

REDIS_PREFIX="macaddr_rw_"
PRINT_DEBUG = True

FNULL = open(os.devnull,'w')


r = None


# Registers address in redis for persistence
def register_addr(ip_addr,mac_addr,expire_time):
    #register w/ reddis
    r.set(REDIS_PREFIX + ip_addr, mac_addr)
    update_rule(ip_addr,mac_addr)


def bootstrap_mikrotik(router):
    tmpfile = tempfile.TemporaryFile()
    subprocess.call("ssh "+router+" ip hotspot host print detail", shell=True,
            stdout=tmpfile)
    tmpfile.seek(0)
    output = tmpfile.read()
    macgrep = re.compile("""\s(\d?)\s*[ADPHS]* mac-address=([0-9A-Z:]*) address=([0-9\.]*) to-address=([0-9\.]*)""")
    entries = macgrep.findall(output, re.MULTILINE)
    for i in entries:
        if i[2] != i[3]: # mikrotek is doing some weird natty shit, 
            del_rule(i[2])
            if PRINT_DEBUG:
                print "Mikrotik fucking up something"
                print i
        print "Adding "+i[2]+"<->"+i[1]+"..."
        r.set(REDIS_PREFIX + i[2], i[1])
        
        
            



def bootstrap():
    bootstrap_mikrotik(config.ROUTER)

    



def reload_state():
    keys = r.keys(REDIS_PREFIX+"*")
    for i in keys:
        macaddr = r.get(i)
        ip = i[len(REDIS_PREFIX):]
        add_rule(ip,macaddr)

# Update mac address
def update_rule(ip_addr,mac_addr):
    old_mac_addr = r.get(REDIS_PREFIX + ip_addr)
    # Only update rule if ip address<->mac changes, to avoid duplicate rules and unnecessary modification of ebtables
    if old_mac_addr != mac_addr:
        del_rule(ip_addr,old_mac_addr)
        add_rule(ip_addr,mac_addr)
        if PRINT_DEBUG:
            print("UPDATE: %s(%s->%s)", ip_addr, old_mac_addr, mac_addr)

# Fires off ebtables commands to add ip/mac rewriting
def add_rule(ip_addr,mac_addr):
    args = ('ebtables'       , 
        '-t'                 , 
        'nat'                , 
        '-A'                 , 
        'TPROXY_MACADDR_FIX' , 
        '-p'                 , 
        'ipv4'               , 
        '--ip-source'        , 
        ip_addr              , 
        '-j'                 , 
        'snat'               , 
        '--to-source'        , 
        mac_addr             , 
        '--snat-target'      , 
        'ACCEPT')
    subprocess.call(args, stdout=FNULL, stderr=subprocess.STDOUT)

# Remove mapping
def del_rule(ip_addr,mac_addr=None):
    if mac_addr==None:
        mac_addr = r.get(REDIS_PREFIX + ip_addr)

    args = ('ebtables'       , 
        '-t'                 , 
        'nat'                , 
        '-D'                 , 
        'TPROXY_MACADDR_FIX' , 
        '-p'                 , 
        'ipv4'               , 
        '--ip-source'        , 
        ip_addr              , 
        '-j'                 , 
        'snat'               , 
        '--to-source'        , 
        mac_addr             , 
        '--snat-target'      , 
        'ACCEPT')
    subprocess.call(args, stdout=FNULL, stderr=subprocess.STDOUT)

# Formats mac addr as string
def format_mac(mac_addr):
    return "{:02x}:{:02x}:{:02x}:{:02x}:{:02x}:{:02x}".format(
          mac_addr[0],
          mac_addr[1],
          mac_addr[2],
          mac_addr[3],
          mac_addr[4],
          mac_addr[5])

# callback fired when ebtables sends dhcp reply packets through bridge
def callback(payload):
    is_dhcpoffer = False
    lease_secs = 0
    data = payload.get_data()
    pkt = ip.IP(data)
    if(pkt.p != ip.IP_PROTO_UDP):
        return

    if PRINT_DEBUG:
        print "proto:", pkt.p
        print "source: %s" % inet_ntoa(pkt.src)
        print "dest: %s" % inet_ntoa(pkt.dst)
        print "dport: %s" % pkt.data.dport
        print "sport: %s" % pkt.data.sport
        print "time: %s" % str(time.time())

    dhcp_reply = dhcp.DHCP(pkt.data.data)
    
    for option,value in dhcp_reply.opts:
        if option == dhcp.DHCP_OPT_MSGTYPE:
            if PRINT_DEBUG:
                print "DHCP msgtype: " + str(struct.unpack('B',value)[0])
            if struct.unpack('B',value)[0] == dhcp.DHCPACK:
                is_dhcpoffer = True
        if option == dhcp.DHCP_OPT_LEASE_SEC:
            lease_secs = struct.unpack(">I",value)[0]
            if PRINT_DEBUG:
                print "Lease secs: " + str(lease_secs)

    if not is_dhcpoffer:
        if PRINT_DEBUG:
            print "Not DHCPACK"
        return;


    expire_time = lease_secs + time.time()
    if PRINT_DEBUG:
        print "Expire Time: " + str(expire_time)

    mac_addr = array.array('B')
    mac_addr.fromstring(dhcp_reply.chaddr)
    if PRINT_DEBUG:
        print "MAC Addr: " + format_mac(mac_addr) 

    register_addr(inet_ntoa(pkt.dst),format_mac(mac_addr),expire_time)
        

if __name__ == '__main__':
    # Change CWD to that of script
    wd = os.path.dirname(os.path.realpath(__file__))
    os.chdir(wd)



    r = redis.Redis(unix_socket_path='/var/run/redis/redis.sock')

    # Flush any possible broken rules
    subprocess.call("./tproxy_flush.sh", stdout=FNULL, stderr=subprocess.STDOUT);

    # Configures kernel parameters, etc
    subprocess.call("./setup.sh", stdout=FNULL, stderr=subprocess.STDOUT);

    # Enable ebtables rewriting chains first before enabling tproxy
    subprocess.call("./ebtables_rewrite.sh", stdout=FNULL, stderr=subprocess.STDOUT);



    # Enable callbacks for rewriting macs
    log = nflog.log()
    log.set_callback(callback)

    log.fast_open(1, AF_BRIDGE)

    bootstrap()
    reload_state()

    try:
        # Finally enable tproxy
        # log.try_run blocks :|, but tproxy ideally should run after try_run.
        # This is ugly
        subprocess.call("sleep 5; ./squid_tproxy.sh", shell=True, stdout=FNULL, stderr=subprocess.STDOUT);

        # Listen for nflog events. This blocks until ctrl-c or killed
        log.try_run()
    except KeyboardInterrupt, e:
        print "interrupted"

    #  Reset everything if killed
    subprocess.call("./tproxy_flush.sh", stdout=FNULL, stderr=subprocess.STDOUT);
    log.unbind(AF_BRIDGE)
    log.close()

