#!/bin/bash
function installVPN(){
	apt-get update
	#remove ppp pptpd
	rm -rf /etc/pptpd.conf
	rm -rf /etc/ppp
	apt-get -y remove ppp pptpd
	
	apt-get -y install ppp pptpd iptables
	echo ms-dns 208.67.222.222 >> /etc/ppp/pptpd-options
	echo ms-dns 208.67.220.220 >> /etc/ppp/pptpd-options
	echo localip 192.168.99.1 >> /etc/pptpd.conf
	echo remoteip 192.168.99.9-99 >> /etc/pptpd.conf

	iptables -t nat -A POSTROUTING -s 192.168.99.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127.0.0' | cut -d: -f2 | awk 'NR==1 { print $1}'`
	sed -i 's/exit\ 0/#exit\ 0/' /etc/rc.local

	echo iptables -t nat -A POSTROUTING -s 192.168.99.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127.0.0' | cut -d: -f2 | awk 'NR==1 { print $1}'` >> /etc/rc.local
	echo exit 0 >> /etc/rc.local
	echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
	sysctl -p
	echo ystest \* intel \* >> /etc/ppp/chap-secrets
	/etc/init.d/pptpd restart
}

function repaireVPN(){
	echo "begin to repaire VPN";
	mknod /dev/ppp c 108 0
	/etc/init.d/pptpd restart
}

function addVPNuser(){
	echo "input user name:"
	read username
	echo "input password:"
	read userpassword
	echo "${username} pptpd ${userpassword} *" >> /etc/ppp/chap-secrets
	/etc/init.d/pptpd restart
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
