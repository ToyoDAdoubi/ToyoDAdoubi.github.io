#!/bin/bash

function installVPN(){
	echo "begin to install VPN services";
	#check wether vps suppot ppp and tun
	
	yum remove -y pptpd ppp
	iptables --flush POSTROUTING --table nat
	iptables --flush FORWARD
	rm -rf /etc/pptpd.conf
	rm -rf /etc/ppp

	wget https://softs.fun/Bash/vpn_rpm/dkms-2.0.17.5-1.noarch.rpm
	wget https://softs.fun/Bash/vpn_rpm/kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
	wget https://softs.fun/Bash/vpn_rpm/pptpd-1.3.4-1.rhel5.1.i386.rpm
	wget https://softs.fun/Bash/vpn_rpm/ppp-2.4.4-9.0.rhel5.i386.rpm

	yum -y install make libpcap iptables gcc-c++ logrotate tar cpio perl pam tcp_wrappers
	rpm -ivh dkms-2.0.17.5-1.noarch.rpm
	rpm -ivh kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
	rpm -qa kernel_ppp_mppe
	rpm -Uvh ppp-2.4.4-9.0.rhel5.i386.rpm
	rpm -ivh pptpd-1.3.4-1.rhel5.1.i386.rpm

	mknod /dev/ppp c 108 0 
	echo 1 > /proc/sys/net/ipv4/ip_forward 
	echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
	echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
	echo "localip 172.16.36.1" >> /etc/pptpd.conf
	echo "remoteip 172.16.36.2-254" >> /etc/pptpd.conf
	echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
	echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd

	pass=`openssl rand 6 -base64`
	if [ "$1" != "" ]
	then pass=$1
	fi

	echo "vpn pptpd ${pass} *" >> /etc/ppp/chap-secrets

	iptables -F
	service iptables save
	iptables --table nat --append POSTROUTING --jump MASQUERADE
	service iptables save

	chkconfig iptables on
	chkconfig pptpd on

	service iptables start
	service pptpd start
	clear
	printf "
####################################################
#                                                  #
# shell tool for install L2TP/ipsec                #
# Fot Centos and Xen VPS only!                     #
# Website: https://www.dou-bi.co                       #
#                                                  #
####################################################

"
	echo "VPN service is installed, your VPN username is vpn, VPN password is ${pass}"
}

function repaireVPN(){
	echo "begin to repaire VPN";
	mknod /dev/ppp c 108 0
	service iptables restart
	service pptpd start
}

function addVPNuser(){
	echo "input user name:"
	read username
	echo "input password:"
	read userpassword
	echo "${username} pptpd ${userpassword} *" >> /etc/ppp/chap-secrets
	service iptables restart
	service pptpd start
}

printf "
####################################################
#                                                  #
# shell tool for install pptpd VPN server          #
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

