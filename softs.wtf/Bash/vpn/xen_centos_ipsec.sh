#!/bin/bash

function installVPN(){
memry=`free -m|grep Mem|awk '{print $2}'`
if (($memry<256)); then
    echo "your VPS's memry is less then 256MB,must disable yum's fastestmirror plugin!"
	sed -i -e 's/enabled=1/enabled=0/'  /etc/yum/pluginconf.d/fastestmirror.conf
	echo "exclude=filesystem" >> /etc/yum.conf
fi
cd ~
vpsip=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 { print $1}'`
psk="dou-bi.com"
echo "Please input PSK:"
read -p "(Default PSK: dou-bi.com):" psk
if [ "$psk" = "" ]; then
	psk="dou-bi.com"
fi

wget https://softs.fun/Bash/vpn_rpm/epel-release-5-4.noarch.rpm

rpm -ihv epel-release-5-4.noarch.rpm

yum -y update
yum install -y ppp iptables make gcc gmp-devel xmlto bison flex xmlto libpcap-devel lsof vim-enhanced openswan
cat >/etc/ipsec.conf<<EOF
# /etc/ipsec.conf - Openswan IPsec configuration file
#
# Manual:     ipsec.conf.5
#
# Please place your own config files in /etc/ipsec.d/ ending in .conf

version 2.0     # conforms to second version of ipsec.conf specification

# basic configuration
config setup
        # Debug-logging controls:  "none" for (almost) none, "all" for lots.
        # klipsdebug=none
        # plutodebug="control parsing"
        # For Red Hat Enterprise Linux and Fedora, leave protostack=netkey
        protostack=netkey
        nat_traversal=yes
        virtual_private=
        oe=off
        # Enable this if you see "failed to find any available worker"
        nhelpers=0

#You may put your configuration (.conf) file in the "/etc/ipsec.d/" and uncomment this.
#include /etc/ipsec.d/*.conf
config setup
    nat_traversal=yes
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12
    oe=off
    protostack=netkey

conn L2TP-PSK-NAT
    rightsubnet=vhost:%priv
    also=L2TP-PSK-noNAT

conn L2TP-PSK-noNAT
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    rekey=no
    ikelifetime=8h
    keylife=1h
    type=transport
    left=$vpsip
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any
EOF

cat >/etc/ipsec.secrets<<EOF
include /etc/ipsec.d/*.secrets
$vpsip %any: PSK "$psk"
EOF

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sysctl -p
iptables -F
service iptables save
service iptables restart

iptables --table nat --append POSTROUTING --jump MASQUERADE

for each in /proc/sys/net/ipv4/conf/*
do
echo 0 > $each/accept_redirects
echo 0 > $each/send_redirects
done

/etc/init.d/ipsec restart

wget https://softs.fun/Bash/vpn_rpm/rp-l2tp-0.4.tar.gz

tar zxvf rp-l2tp-0.4.tar.gz
cd rp-l2tp-0.4
./configure
make
cp handlers/l2tp-control /usr/local/sbin/
mkdir /var/run/xl2tpd/
ln -s /usr/local/sbin/l2tp-control /var/run/xl2tpd/l2tp-control

cd ..
wget -c https://softs.fun/Bash/vpn_rpm/xl2tpd-1.2.8.tar.gz
tar zxvf xl2tpd-1.2.8.tar.gz
cd xl2tpd-1.2.8
make install
mkdir /etc/xl2tpd
rm -rf /etc/xl2tpd/xl2tpd.conf
touch /etc/xl2tpd/xl2tpd.conf
cat >/etc/xl2tpd/xl2tpd.conf<<EOF
[global]
ipsec saref = yes
 
[lns default]
local ip = 10.10.11.1
ip range = 10.10.11.2-10.10.11.245
refuse chap = yes
refuse pap = yes
require authentication = yes
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

rm -rf /etc/ppp/options.xl2tpd
touch /etc/ppp/options.xl2tpd
cat >/etc/ppp/options.xl2tpd<<EOF
require-mschap-v2
ms-dns 8.8.8.8
ms-dns 8.8.4.4
asyncmap 0
auth
crtscts
lock
hide-password
modem
debug
name l2tpd
proxyarp
lcp-echo-interval 30
lcp-echo-failure 4
EOF

cat >>/etc/rc.local<<EOF
iptables --table nat --append POSTROUTING --jump MASQUERADE
/etc/init.d/ipsec restart
/usr/bin/zl2tpset
/usr/local/sbin/xl2tpd
EOF

iptables --table nat --append POSTROUTING --jump MASQUERADE
service iptables save
chkconfig iptables on
service iptables start
/usr/local/sbin/xl2tpd

pass=`openssl rand 6 -base64`
if [ "$1" != "" ]
then pass=$1
fi
echo "vpn * ${pass} *" >> /etc/ppp/chap-secrets

clear
printf "
####################################################
#                                                  #
# shell tool for install L2TP/ipsec VPN server     #
# Fot Centos and Xen VPS only!                     #
# Website: https://www.dou-bi.co                       #
#                                                  #
####################################################

"
echo "L2TP VPN service is installed, your L2TP VPN username is vpn, VPN password is ${pass}"
}

function repaireVPN(){
	echo "begin to repaire VPN";
	mknod /dev/ppp c 108 0
	service iptables restart
	/etc/init.d/ipsec restart
	killall xl2tpd
	/usr/local/sbin/xl2tpd
}

function addVPNuser(){
	echo "input user name:"
	read username
	echo "input password:"
	read userpassword
	echo "${username} * ${userpassword} *" >> /etc/ppp/chap-secrets
	service iptables restart
	/etc/init.d/ipsec restart
	killall xl2tpd
	/usr/local/sbin/xl2tpd
}

printf "
####################################################
#                                                  #
# shell tool for install L2TP/ipsec VPN server     #
# Fot Centos and Xen VPS only!                     #
# Website: https://www.dou-bi.co                       #
#                                                  #
####################################################

which do you want to?input the number:
1. install VPN service
2. repaire VPN service
3. add VPN user
"
read num

case "$num" in
[1] ) (installVPN);;
[2] ) (repaireVPN);;
[3] ) (addVPNuser);;
*) echo "nothing,exit";;
esac