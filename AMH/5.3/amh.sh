#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear;
# Logo 	******************************************************************
CopyrightLogo='
                                   AMH 5.3                                  
                            Powered by amh.sh 2006-2015                     
                         http://amh.sh All Rights Reserved                  
                                                                            
==========================================================================';
echo "$CopyrightLogo";

# VAR 	******************************************************************
InstallModel=$1;
InstallFrom=$2;
SysName='';
SysBit='';
CpuNum='';
RamTotal='';
RamSwap='';
StartDate='';
StartDateSecond='';
RandomValue=$RANDOM;
IPAddress=`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1`;
DefaultPassword='';
InstallStatus='';
ServerLocation='';
MirrorHost='code.amh.sh';

# Version
AMHVersion='amh-5.3';
AMHConfVersion='amh-conf-5.3';
LibiconvVersion='libiconv-1.14';
NginxVersion='nginx-generic-1.6';
MysqlVersion='mysql-generic-5.5';
PhpVersion='php-generic-5.3';

# InstallModel
if [ "$InstallModel" == 'gcc' ]; then
	NginxVersion='nginx-1.6';
	MysqlVersion='mysql-5.5';
	PhpVersion='php-5.3';
elif echo "$InstallModel" | grep ','; then
	NginxVersion=`echo $InstallModel | awk -F ',' '{print $1}'`;
	MysqlVersion=`echo $InstallModel | awk -F ',' '{print $2}'`;
	PhpVersion=`echo $InstallModel | awk -F ',' '{print $3}'`;
fi;

# Function List	*******************************************************************************
function CheckSystem()
{
	[ $(id -u) != '0' ] && echo '[Error] Please use root to install AMH.' && exit;
	egrep -i "debian" /etc/issue /proc/version >/dev/null && SysName='Debian';
	egrep -i "ubuntu" /etc/issue /proc/version >/dev/null && SysName='Ubuntu';
	whereis -b yum | grep '/yum' >/dev/null && SysName='CentOS';
	#egrep -i "red hat|redhat" /etc/issue /proc/version >/dev/null && SysName='RedHat';
	#egrep -i "centos" /etc/issue /proc/version >/dev/null && SysName='CentOS';
	[ "$SysName" == ''  ] && echo '[Error] Your system is not supported install AMH' && exit;
	[ "$IPAddress" == '' ] && IPAddress='ip';

	SysBit='32' && [ `getconf WORD_BIT` == '32' ] && [ `getconf LONG_BIT` == '64' ] && SysBit='64';
	CpuNum=`cat /proc/cpuinfo | grep 'processor' | wc -l`;
	echo "${SysName} ${SysBit}Bit";
	RamTotal=`free -m | grep 'Mem' | awk '{print $2}'`;
	RamSwap=`free -m | grep 'Swap' | awk '{print $2}'`;
	echo "Server ${IPAddress}";
	echo "${CpuNum}*CPU, ${RamTotal}MB*RAM, ${RamSwap}MB*Swap";
	echo '';
	
	if ! echo "${MysqlVersion}${PhpVersion}" | grep '.*generic.*generic.*' >/dev/null; then
		RamSum=$[$RamTotal+$RamSwap];
		[ "$SysBit" == '32' ] && [ "$RamSum" -lt '250' ] && \
		echo -e "[Error] Not enough memory install AMH. \n(32bit system need memory: ${RamTotal}MB*RAM + ${RamSwap}MB*Swap > 250MB)" && exit;

		if [ "$SysBit" == '64' ] && [ "$RamSum" -lt '480' ];  then
			echo -e "[Error] Not enough memory install AMH. \n(64bit system need memory: ${RamTotal}MB*RAM + ${RamSwap}MB*Swap > 480MB)";
			[ "$RamSum" -gt '250' ] && echo "[Notice] Please use 32bit system.";
			exit;
		fi;
	fi;
}


function SetPassword()
{
	read -p '[Notice] Please input AMH and MySQL password:' DefaultPassword;
	if [ "$DefaultPassword" == '' ]; then
		echo '[Error] AMH and MySQL password is empty.';
		SetPassword;
	else
		echo '[OK] Your AMH and MySQL password is:';
		echo $DefaultPassword;
	echo '==========================================================================';
	fi;
}

function ConfirmInstall()
{
	echo -e "[Notice] Confirm Install - AMH 5.3 \nPlease select your nearest mirror: (1~4)"
	select selected in 'China [CN]' 'United States [USA]' 'Japan [JP]' 'Other [ALL]' 'Exit'; do break; done;
	[ "$selected" == 'Exit' ] && echo 'Exit Install.' && exit;
	[ "$selected" != '' ] &&  echo -e "[OK] You Selected: ${selected}\n" && ServerLocation=$selected && return 0;
	ConfirmInstall;
}

function CloseSelinux()
{
	[ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
	setenforce 0 >/dev/null 2>&1;
}

function InstallReady()
{
	rm -rf /etc/localtime;
	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;
	#\cp /etc/resolv.conf /etc/resolv-backup.conf;
	#echo -e "options timeout:1 attempts:1 rotate\nnameserver 8.8.8.8\nnameserver 114.114.114.114" >/etc/resolv.conf;

	echo "$ServerLocation" | grep -q 'China' && MirrorHost='code3.amh.sh';
	if [ "$SysName" == 'CentOS' ]; then
		yum_repos_s=`ls /etc/yum.repos.d | wc -l`;
		if [ "$yum_repos_s" == '0' ]; then
			sed -i 's/^exclude/#exclude/' /etc/yum.conf;
			release_n='5' && grep 'release 6' /etc/issue && release_n='6';
			basearch_n='i386' && [ "$SysBit" == '64' ] && basearch_n='x86_64';
			cd /etc/yum.repos.d;
			wget http://${MirrorHost}/files/amh-redhat${release_n}-base.repo -O amh-redhat${release_n}-base.repo;
			sed -i "s#\$releasever#$release_n#g" amh-redhat${release_n}-base.repo;
			sed -i "s#\$basearch#$basearch_n#g" amh-redhat${release_n}-base.repo;
			yum clean all;
			yum makecache;
		fi;
		yum -y install gcc gcc-c++ make curl bzip2 ntp vixie-cron;
	else
		apt-get -y update;
		apt-get -y install gcc g++ make curl bzip2 ntpdate cron;
	fi;

	ntpdate -u pool.ntp.org;
	StartDate=$(date);
	StartDateSecond=$(date +%s);
	echo "Start time: ${StartDate}";

	groupadd www;
	useradd -m -s /sbin/nologin -g www www;

	mkdir -p /root/amh/{modules,conf};
	mkdir -p /home/{wwwroot,usrdata};
	cd /tmp/;
	wget http://${MirrorHost}/files/${AMHConfVersion}.tar.gz -O ${AMHConfVersion}.tar.gz;
	tar -zxvf ${AMHConfVersion}.tar.gz;
	\cp -a ./${AMHConfVersion}/conf /root/amh/;
	sed -i 's/curl -r/curl -d "new=y" -r/' /root/amh/conf/amh-base;
	sed -i 's/-O/--post-data="new=y" -O/' /root/amh/conf/amh-base;
	sed -i 's/TimeOut=1/TimeOut=2/' /root/amh/conf/amh-base;
	chmod -R 775 /root/amh/conf /root/amh/modules;
	gcc -o /bin/amh -Wall ./${AMHConfVersion}/conf/amh.c;
	chmod 4775 /bin/amh;
	echo $ServerLocation >/root/amh/conf/location.conf;
	rm -rf ${AMHConfVersion}.tar.gz ${AMHConfVersion} /root/amh/conf/amh.c;
}

function InstallBaseModule()
{
	amh download ${LibiconvVersion};
	amh download ${MysqlVersion};
	amh download ${NginxVersion};
	amh download ${PhpVersion};
	amh download ${AMHVersion};

	module_arr=("${LibiconvVersion}" "${MysqlVersion}" "${NginxVersion}" "${PhpVersion}" "${AMHVersion}");
	for v in ${module_arr[*]}; do
		[ ! -d "/root/amh/modules/$v" ] && echo "[Error] $v download failed." && exit;
	done;

	amh ${LibiconvVersion} install && \
	amh ${PhpVersion} install && \
	amh ${MysqlVersion} install ${DefaultPassword} && \
	amh ${NginxVersion} install && \
	amh ${AMHVersion} install ${NginxVersion} ${MysqlVersion} ${PhpVersion} ${DefaultPassword} ${DefaultPassword} ${InstallFrom} && InstallStatus='success';
}
function Convert()
{
	cd /root/;
	rm -rf convert;
	wget https://raw.githubusercontent.com/thesadboy/CentOS/master/AMH/5.3/convert.tar.gz  --no-check-certificate;
	tar -zxvf convert.tar.gz;
	\cp -a ./convert/web/* /usr/local/amh-5.3/web;
	chmod -R 775 /usr/local/amh-5.3/web;
	\cp -a ./convert/amh-base /root/amh/conf;
	chmod -R 775 /root/amh/conf/amh-base;
	\cp -a ./convert/AMHScript /root/amh/modules/amh-5.3;
	chmod -R 775 /root/amh/modules/amh-5.3/AMHScript;
	rm -rf convert convert.tar.gz;
}


# AMH Installing ****************************************************************************
CheckSystem;
SetPassword;
ConfirmInstall;
CloseSelinux;
InstallReady;
InstallBaseModule;
Convert;

echo '==========================================================================';
if [ "${InstallStatus}" == 'success' ]; then
	echo '[AMH] Congratulations, AMH 5.3 install completed.';
	echo "AMH Management: ";
	echo "http://${IPAddress}:8888";
	echo "https://${IPAddress}:9999";
	echo 'AMH User: admin';
	echo -e "AMH Password: \033[36m${DefaultPassword}\033[0m ";
	echo "MySQL User: root";
	echo -e "MySQL Password: \033[36m${DefaultPassword}\033[0m ";
	echo '';
	echo "Start time: ${StartDate}";
	echo "Completion time: $(date) (Use: $[($(date +%s)-StartDateSecond)/60] minute)";
	echo 'More help please visit:http://amh.sh';
else
	echo 'Sorry, Failed to install AMH';
	echo 'Please contact us: http://amh.sh';
fi;
echo '==========================================================================';

