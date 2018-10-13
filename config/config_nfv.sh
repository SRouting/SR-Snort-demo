#!/bin/bash

DAQ_VERSION="2.0.6"

# Install required packages 
sudo apt-get update
apt-get -y install libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0

cd ~/
wget https://www.snort.org/downloads/snort/daq-${DAQ_VERSION}.tar.gz && tar xvfz daq-${DAQ_VERSION}.tar.gz && cd daq-${DAQ_VERSION} && ./configure --enable-nfq=yes && make && sudo make install

# Configure Interfaces
ifconfig eth1 up
ip -6 addr add 12::2/64 dev eth1

ifconfig eth2 up
ip -6 addr add 23::2/64 dev eth2

# Enable forwarding
sysctl -w net.ipv6.conf.all.forwarding=1

# Accept SRv6 traffic
sysctl -w net.ipv6.conf.all.seg6_enabled=1
sysctl -w net.ipv6.conf.lo.seg6_enabled=1
sysctl -w net.ipv6.conf.eth1.seg6_enabled=1
sysctl -w net.ipv6.conf.eth2.seg6_enabled=1

# Configure VNFs
cd ~/
rm -rf SR-snort-demo
git clone https://github.com/SRouting/SR-Snort-demo
cd SR-Snort-demo/config/

sh deploy-term.sh add vnf1 veth1 inet6 fd00:2:f1::1/64 fd00:2:f1::2/64
ip netns exec vnf1 sysctl -w net.ipv6.conf.all.seg6_enabled=1
ip netns exec vnf1 sysctl -w net.ipv6.conf.lo.seg6_enabled=1
ip netns exec vnf1 sysctl -w net.ipv6.conf.veth0-vnf1.seg6_enabled=1
ip netns exec vnf1 ip -6 route add local 2::f1/128 dev lo

sh deploy-term.sh add vnf2 veth2 inet6 fd00:2:f2::1/64 fd00:2:f2::2/64
ip netns exec vnf2 sysctl -w net.ipv6.conf.all.seg6_enabled=1
ip netns exec vnf2 sysctl -w net.ipv6.conf.lo.seg6_enabled=1
ip netns exec vnf2 sysctl -w net.ipv6.conf.veth0-vnf2.seg6_enabled=1
ip netns exec vnf2 ip -6 route add local 2::f2/128 dev lo


# Configure Routing
ip -6 route add 2::f1/128 via fd00:2:f1::2
ip -6 route add 2::f2/128 via fd00:2:f2::2
ip -6 route add 3::/64 via 23::3
ip -6 route add 1::/64 via 12::1


# configure Snort (IDS)
sudo mkdir -p /etc/snort/ /etc/snort/rules/ /var/log/snort
touch /etc/snort/snort.ids.conf /etc/snort/rules/local.ids.rule
echo 'var RULE_PATH rules' >> /etc/snort/snort.ids.conf
echo 'include $RULE_PATH/local.ids.rule' >> /etc/snort/snort.ids.conf
echo 'alert udp A::2 any -> B::2 5000 (msg:"ALERT !!! UDP packet src=A::2 dst=B::2 dport= 5000 "; sid:5000)' >> /etc/snort/rules/local.ids.rule
echo 'preprocessor arpspoof' >> /etc/snort/snort.ids.conf

# configure Snort (IPS)
touch /etc/snort/snort.ips.conf /etc/snort/rules/local.ips.rule
echo 'var RULE_PATH rules' >> /etc/snort/snort.ips.conf
echo 'include $RULE_PATH/local.ips.rule' >> /etc/snort/snort.ips.conf
echo 'drop udp A::2 any -> B::2 6000 (msg:"UDP packet src= A::2 dst=B::2 dport= 6000 "; sid:6000)' >> /etc/snort/rules/local.ips.rule
echo 'preprocessor arpspoof' >> /etc/snort/snort.ips.conf
echo 'config daq: nfq' >> /etc/snort/snort.ips.conf 
echo 'config daq_dir: /usr/local/lib/daq' >> /etc/snort/snort.ips.conf 
echo 'config daq_mode: inline' >> /etc/snort/snort.ips.conf
echo 'config daq_var: queue=0' >> /etc/snort/snort.ips.conf
echo 'config daq_var: proto=ip6' >> /etc/snort/snort.ips.conf
ip netns exec vnf2 ip6tables -I INPUT -d 2::f2 -j NFQUEUE --queue-num=0
