#!/bin/bash

function installVPN(){
	echo "begin to install L2TP VPN services";
	
	yum remove -y pptpd ppp
	iptables --flush POSTROUTING --table nat
	iptables --flush FORWARD
	rm -rf /etc/pptpd.conf
	rm -rf /etc/ppp
	
	
	
	yum -y install openswan gcc libpcap-devel ppp 

	mknod /dev/ppp c 108 0 
	echo 1 > /proc/sys/net/ipv4/ip_forward 
	echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
	echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
	echo "/usr/local/sbin/xl2tpd" >> /etc/rc.local

	cd /tmp/
	wget https://softs.fun/Bash/vpn_rpm/rp-l2tp-0.4.tar.gz
	tar zxvf rp-l2tp-0.4.tar.gz
	cd rp-l2tp-0.4
	./configure
	make
	cp -rf handlers/l2tp-control /usr/local/sbin/
	mkdir /var/run/xl2tpd/
	ln -s /usr/local/sbin/l2tp-control /var/run/xl2tpd/l2tp-control
	
	cd ..
	
	wget -c https://softs.fun/Bash/vpn_rpm/xl2tpd-1.2.8.tar.gz
	tar -zxf xl2tpd-1.2.8.tar.gz
	cd xl2tpd-1.2.8
	make install
	mkdir /etc/xl2tpd
	touch /etc/xl2tpd/xl2tpd.conf
	touch /etc/ppp/options.xl2tpd
	
	cat >/etc/xl2tpd/xl2tpd.conf<<END
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
END
	cat >/etc/ppp/options.xl2tpd<<END
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
END
	
	pass=`openssl rand 6 -base64`
	if [ "$1" != "" ]
	then pass=$1
	fi

	echo "vpn * ${pass} *" >> /etc/ppp/chap-secrets

	iptables -t nat -A POSTROUTING -s 10.10.10/8 -o venet0 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127.0.0' | cut -d: -f2 | awk 'NR==1 { print $1}'`
	iptables -A FORWARD -s `ifconfig  | grep 'inet addr:'| grep -v '127.0.0' | cut -d: -f2 | awk 'NR==1 { print $1}'`/32 -o venet0 -j ACCEPT
	service iptables save

	chkconfig iptables on
	
	service iptables start
	/usr/local/sbin/xl2tpd
	
	echo "L2TP VPN service is installed, your L2TP VPN username is vpn, VPN password is ${pass}"
	
}

function repaireVPN(){
	echo "begin to repaire VPN";
	mknod /dev/ppp c 108 0
	service iptables restart
	
}

function addVPNuser(){
	echo "input user name:"
	read username
	echo "input password:"
	read userpassword
	echo "${username} * ${userpassword} *" >> /etc/ppp/chap-secrets
	service iptables restart
	
}

echo "which do you want to?input the number."
echo "1. install VPN service"
echo "2. repaire VPN service"
echo "3. add VPN user"
read num

case "$num" in
[1] ) (installVPN);;
[2] ) (repaireVPN);;
[3] ) (addVPNuser);;
*) echo "nothing,exit";;
esac

