#!/bin/bash
echo "download and install pptpd.sh"
wget https://raw.githubusercontent.com/thesadboy/CentOS/master/pptpd.sh
sh ./pptpd.sh nickzhang zhangliangnick
echo "download and install node-install.sh"
wget https://raw.githubusercontent.com/thesadboy/CentOS/master/node-install.sh
sh ./node-install.sh
echo "download shadowsocks.sh"
wget https://raw.githubusercontent.com/thesadboy/CentOS/master/shadowsocks.sh
sh ./shadowsocks.sh
echo "clean"
rm -rf node-install.sh pptpd.sh shadowsocks.sh
