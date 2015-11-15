#!/bin/bash
#
# Script by Christoph Daniel Miksche
# License: GNU General Public License
#
# Contact:
# > http://cdm.webpage4.me
# > Twitter: CMiksche
# > GitHub: CMiksche
#
# Run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
# Include config
source ./config.sh
# Update
apt-get update && apt-get upgrade -y
# Dist-Upgrade
apt-get dist-upgrade -y
# Install
apt-get install ufw rkhunter fail2ban nano sudo htop whois curl nodejs -y
# Install Composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
# (Re-)Start
service ufw restart
service fail2ban restart
# Daily Update
su -c "echo -e \"#! /bin/sh\napt-get update && apt-get upgrade -y\" >> /etc/cron.daily/update && chmod a+x /etc/cron.daily/update"
# Change SSH Port
sed -i "s/Port 22/Port $sshport/g" /etc/ssh/sshd_config
# Allow Ports
ufw allow proto tcp from any to any port "$sshport"
ufw allow http
ufw allow https
ufw allow ftp
# Enable Firewall 
ufw enable

# Change E-Mail in rkhunter config
sed -i "s/user@domain.tld/$systemmail/g" /etc/rkhunter.conf
sed -i "s/me@mydomain/$systemmail/g" /etc/rkhunter.conf
sed -i "s/root@mydomain//g" /etc/rkhunter.conf
sed -i "s/#MAIL-ON-WARNING/MAIL-ON-WARNING/g" /etc/rkhunter.conf
sed -i "s/#MAIL_CMD/MAIL_CMD/g" /etc/rkhunter.conf

# Add Default User
useradd -m -c "Default User" "$defaultuser"
# Set Passwort for Default User
echo "$defaultuser":"$defaultpass" | chpasswd
addgroup --system sshusers
adduser "$defaultuser" sshusers
# Set SSH-Users
sed -i "s/AllowUsers/AllowUsers $defaultuser/g" /etc/ssh/sshd_config
# Set SSH-Groups
sed -i "s/AllowGroups/AllowGroups sshusers/g" /etc/ssh/sshd_config
# Disable SSH-Root-Login
sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin without-password/PermitRootLogin no/g" /etc/ssh/sshd_config

# Copy Shell-Login-File
cp ./copy/shell-login.sh /opt/shell-login.sh

# Restart Services
/etc/init.d/ssh restart
