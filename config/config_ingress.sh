#!/bin/bash

# Configure Interfaces
ifconfig eth1 up
ip -6 addr add 12::1/64 dev eth1

# Enable forwarding
sysctl -w net.ipv6.conf.all.forwarding=1

# Accept SRv6 traffic
sysctl -w net.ipv6.conf.all.seg6_enabled=1
sysctl -w net.ipv6.conf.lo.seg6_enabled=1
sysctl -w net.ipv6.conf.eth1.seg6_enabled=1

# Configure Branches (BR1 and BR2)
cd ~/
rm -rf SR-snort-demo
git clone https://github.com/SRouting/SR-Snort-demo
cd SR-Snort-demo/config/
sh deploy-term.sh add site_a veth0 inet6 A::1/64 A::2/64

# Configure SR SFC policies
ip -6 route add B::/64 encap seg6 mode encap segs 2::f1,2::f2,3::D6 dev eth1

# Configure Routing
ip -6 route add 2::/64 via 12::2

# Configure SRv6 End.D6 behaviour for reverse traffic (B-->A)
ip -6 route add local 1::d6/128 dev lo
