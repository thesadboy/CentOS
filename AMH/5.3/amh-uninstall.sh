#!/bin/bash

killall php-fpm
amh nginx stop
amh mysql stop

rm /root/amh -rf;
rm /home/usrdata /home/wwwroot -rf;
rm /usr/local/amh* -rf;
rm /usr/local/libiconv* -rf;
rm /usr/local/nginx* -rf;
rm /usr/local/mysql* -rf;
rm /usr/local/php* -rf;
rm /etc/init.d/amh-start /etc/amh-iptables /bin/amh -f;

echo "amh uninstalled";