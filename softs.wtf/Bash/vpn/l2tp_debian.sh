#!/bin/sh
 
#VPN 账号
vpn_name="l2tp"
 
#VPN 密码
vpn_password="dou-bi.co"
 
#设置 PSK 预共享密钥
psk_password="dou-bi.co"
 
#获取公网IP
ip=`ifconfig | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
 
 
#安装 openswan、xl2tpd(有弹对话框的话直接按回车就行)
apt-get install -y openswan xl2tpd screen
 
 
#备份 /etc/ipsec.conf 文件
ipsec_conf="/etc/ipsec.conf"
if [ -f $ipsec_conf ]; then
    cp $ipsec_conf $ipsec_conf.bak
fi
echo "
version 2.0
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
    left=$ip
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any
    dpddelay=40
    dpdtimeout=130
    dpdaction=clear
" > $ipsec_conf
 
 
 
#备份 /etc/ipsec.secrets 文件
ipsec_secrets="/etc/ipsec.secrets"
if [ -f $ipsec_secrets ]; then
    cp $ipsec_secrets $ipsec_secrets.bak
fi
echo "
$ip   %any:  PSK \"$psk_password\"
" >> $ipsec_secrets
 
 
 
#备份 /etc/sysctl.conf 文件
sysctl_conf="/etc/sysctl.conf"
if [ -f $sysctl_conf ]; then
    cp $sysctl_conf $sysctl_conf.bak
fi
echo "
net.ipv4.ip_forward = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
" >> $sysctl_conf
sysctl -p
 
for each in /proc/sys/net/ipv4/conf/*
do
    echo 0 > $each/accept_redirects
    echo 0 > $each/send_redirects
done
 
 
#设置 l2tp
xl2tpd="/etc/xl2tpd/xl2tpd.conf"
if [ -f $xl2tpd ]; then
    cp $xl2tpd $xl2tpd.bak
fi
echo "
[global]
ipsec saref = yes
 
[lns default]
ip range = 10.1.2.2-10.1.2.255
local ip = 10.1.2.1
refuse chap = yes
refuse pap = yes
require authentication = yes
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
" > $xl2tpd
 
 
#设置 ppp
options_xl2tpd="/etc/ppp/options.xl2tpd"
if [ -f $options_xl2tpd ]; then
    cp $options_xl2tpd $options_xl2tpd.bak
fi
echo "
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
" > $options_xl2tpd
 
#添加 VPN 账号
chap_secrets="/etc/ppp/chap-secrets"
if [ -f $chap_secrets ]; then
    cp $chap_secrets $chap_secrets.bak
fi
echo "
$vpn_name * $vpn_password *
" >> $chap_secrets
 
 
#设置 iptables 的数据包转发
iptables --table nat --append POSTROUTING --jump MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
 
 
/etc/init.d/ipsec stop
 
/etc/init.d/xl2tpd stop
 
/etc/init.d/ipsec start
 
screen -dmS xl2tpd xl2tpd -D
 
ipsec verify
 
echo "###########################################"
echo "##    L2TP VPN SETUP COMPLETE!"
echo "##    VPN IP          :   $ip"
echo "##    VPN USER        :   $vpn_name"
echo "##    VPN PASSWORD    :   $vpn_password"
echo "##    VPN PSK         :   $psk_password"
echo "###########################################"