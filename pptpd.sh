yum remove -y pptpd ppp
iptables --flush POSTROUTING --table nat
iptables --flush FORWARD
rm -rf /etc/pptpd.conf
rm -rf /etc/ppp

rpm -Uvh http://poptop.sourceforge.net/yum/stable/rhel6/pptp-release-current.noarch.rpm

yum -y install make libpcap iptables gcc-c++ logrotate tar cpio perl pam tcp_wrappers ppp pptpd

mknod /dev/ppp c 108 0
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
echo "localip 192.168.10.1" >> /etc/pptpd.conf
echo "remoteip 192.168.10.10-254" >> /etc/pptpd.conf
echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd

pass=`openssl rand 6 -base64`
name='vpn'
if [ "$1" != "" ]
then name=$1
fi
if [ "$2" != "" ]
then pass=$2
fi
echo "${name}   pptpd   ${pass}     *" >> /etc/ppp/chap-secrets

iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 { print $1}'`
iptables -A INPUT -p tcp -m tcp --dport 1723 -j ACCEPT
iptables -A FORWARD -p tcp --syn -s 192.168.10.0/24 -j TCPMSS --set-mss 1356
service iptables save

chkconfig iptables on
chkconfig pptpd on

service iptables start
service pptpd start

echo "VPN service is installed, your VPN username is ${name}, VPN password is ${pass}"
