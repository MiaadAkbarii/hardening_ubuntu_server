 #! /bin/bash

#     [

#author=Miad Akbari

#linkedin=https://linkedin.com/in/miadakbari

#github=MiaadAkbarii

#         ]



usage() {
	echo "Usage: hardening_avan_group.sh [-u avan]";
	exit 1;
}

checkAdmin() {
	if (( $EUID != 0 ))
	then
		echo "[-] Error - Please run the script with administrative user account";
		exit 1;
	fi
}

upgrade() {
	echo "[+] Upgrading packages ...";
	apt-get update;
	apt-get -y dist-upgrade;
	apt install net-tools
	apt install nginx
	apt-get -y autoremove;
	clear
}

checkPackage() {
	dpkg -s $1 &> /dev/null
	if [ $? -eq 1 ]
	then
		echo "[+] Package $1 not found, installing ...";
		apt-get -qq -y install $1 &> /dev/null;
	fi
}

configureAutomaticUpgrade() {
	echo "[+] Configuring automatic upgrade ...";
	checkPackage "unattended-upgrades"
	checkPackage "apt-config-auto-update"
	echo " **************************************  *Avan*    Replace Auto Update To apt.conf *Avan*     **************************************"
	sed -i '/"${distro_id}:${distro_codename}-updates"/ s/^\/\///' /etc/apt/apt.conf.d/50unattended-upgrades
	sed -i 's/\/\/Unattended-Upgrade::Automatic-Reboot "false";/Unattended-Upgrade::Automatic-Reboot "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades;
	sed -i 's/\/\/Unattended-Upgrade::Automatic-Reboot-WithUsers "true";/Unattended-Upgrade::Automatic-Reboot-WithUsers "false";/g' /etc/apt/apt.conf.d/50unattended-upgrades;
	sed -i 's/\/\/Unattended-Upgrade::Automatic-Reboot-Time "02:00";/Unattended-Upgrade::Automatic-Reboot-Time "08:00";/g' /etc/apt/apt.conf.d/50unattended-upgrades;
	sed -i 's/Unattended-Upgrade::DevRelease "auto";/\/\/Unattended-Upgrade::DevRelease "auto";/g' /etc/apt/apt.conf.d/50unattended-upgrades;
}
       echo " **************************************   *Avan*  Updated autoupdate > apt.conf *Avan*    **************************************"   
setUpFirewall() {
	echo "[+] Configuring firewall ...";
	checkPackage "ufw"
	cp /etc/default/ufw /etc/default/ufw.bck
	sed -i 's/IPV6=no/IPV6=yes/g' /etc/default/ufw
	ufw default deny incoming &> /dev/null;
	ufw default allow outgoing &> /dev/null;
	echo "[+] Firewall allow outgoing connection";
	ufw allow 4563/tcp  &> /dev/null; #prot 4563 for ssh server
	ufw allow http &> /dev/null;
	ufw allow https &> /dev/null;
	ufw allow 10051/tcp &> /dev/null;
	echo "[+] Firewall allow only incoming connection on port 4563 (SSH)";
	echo "[+] Firewall allow only incoming connection on port 80 (HTTP)";
	echo "[+] Firewall allow only incoming connection on port 443 (HTTPS)";
	echo "[+] Firewall allow only incoming connection on port 10051 (ZABBIX)";
	ufw --force enable &> /dev/null;
}

configureNTP() {
	echo "[+] Configuring NTP server...";
	cp /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.bck;
	sed -i 's/#NTP=/NTP=ntp.ubuntu.com/g' /etc/systemd/timesyncd.conf;
	sed -i 's/#PollIntervalMinSec=32/PollIntervalMinSec=60/g' /etc/systemd/timesyncd.conf;
	sed -i 's/#PollIntervalMaxSec=2048/PollIntervalMaxSec=2048/g' /etc/systemd/timesyncd.conf;
	timedatectl set-ntp on;
}


configureOTP() {
	echo "[+] Configuring Google OTP...";
	checkPackage "libpam-google-authenticator";
	checkPackage "openssh-server";
	cp /etc/pam.d/sshd /etc/pam.d/sshd.bck;
	echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd;
	cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bck;
	sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/Port 4563/PermitRootLogin no/g' /etc/ssh/sshd_config;
	echo "AuthenticationMethods keyboard-interactive" >> /etc/ssh/sshd_config;
}

remountProc() {
	echo "[+] Mounting /proc with user restriction...";
	cp /etc/fstab /etc/fstab.bck
	echo "" >> /etc/fstab
	echo "#Mount /proc with hidepid=2 parameter, so users cannot see other users processes" >> /etc/fstab
	echo "proc    /proc    proc    defaults,nosuid,nodev,noexec,relatime,hidepid=2     0     0" >> /etc/fstab
}

addTimestampToHistory() {
	echo "[+] Adding timestamp to bash history...";
	cp /etc/profile /etc/profile.bck
	echo "" >> /etc/profile
	echo "#Add timestamp to command in bash history" >> /etc/profile
	echo "export HISTTIMEFORMAT='%F %T '" >> /etc/profile
}

disableRootUser() {
	echo "[+] Disabling root user ...";
	passwd -l root &> /dev/null;
}
zabbix_agent() {
	echo "[+] Install agent and configuration zabbix agent";
	wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+focal_all.deb
	dpkg -i zabbix-release_5.0-1+focal_all.deb
	apt update
	apt install zabbix-agent
        sed -i 's/Server= 10.10.0.90/Hostname= mon.homapharmed.com/g /etc/zabbix/zabbix_agetnd.conf/';
	systemctl restart zabbix-agent
	systemctl enable zabbix-agent
	systemctl restart zabbix-agent
	systemctl status zabbix-agent
	echo "  *******************  *Avan   Finish install agnet   *Avan*  ********************"
	
printInfo() {
	host=`hostname`;
	read $host
	echo "[+] Hardening operations completed";
	echo "";
	echo "What to do:";
	echo "	* Download and open 'Google authenticator' app on your smartphone";
	echo "	* Add item";
	echo "	* Insert $host";
	echo "	* Insert $otp_code";
	echo "	* Reboot with command 'reboot'";
	echo "	* Connect to $hostname with SSH client";
	echo "	* Insert OTP token from 'Google Autheticator' app";
	echo "	* Have fun";
	echo "";
}

while getopts ":u:" flag
do
	case ${flag} in
        u) [ ! -z "${OPTARG}" ] || usage
		   username=${OPTARG}
		   checkAdmin
		   upgrade
		   configureAutomaticUpgrade
		   setUpFirewall
		   configureNTP
		   configureOTP
		   remountProc
		   addTimestampToHistory
		   disableRootUser
		   zabbix_agent
		   printInfo
		   exit 0;;
	esac
	echo " **********************************      *Avan* Complate  Hardening server  *Avan*   ************************************"
done

