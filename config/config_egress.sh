#!/bin/bash

#interfaces configuration
ifconfig eth1 up
ip -6 addr add 23::3/64 dev eth1

# Enable forwarding
sysctl -w net.ipv6.conf.all.forwarding=1

# Accept SRv6 traffic
sysctl -w net.ipv6.conf.all.seg6_enabled=1
sysctl -w net.ipv6.conf.lo.seg6_enabled=1
sysctl -w net.ipv6.conf.eth1.seg6_enabled=1

# Configure External network (ext)
cd ~/
rm -rf SR-snort-demo
git clone https://github.com/SRouting/SR-Snort-demo
cd SR-Snort-demo/config/
sh deploy-term.sh add site_b veth0 inet6 B::1/64 B::2/64

# Configure Routing
ip -6 route add 2::/64 via 23::2

# Configure SRv6 End.D6 behaviour for traffic going to Ext
ip -6 route add local 3::d6/128 dev lo

# Configure SR SFC policies for reverse traffic
ip -6 route add A::/64 encap seg6 mode encap segs 2::f2,2::f1,1::D6 dev eth1
