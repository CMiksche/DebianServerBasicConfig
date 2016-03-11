#!/bin/bash
#
#  ____       _     _               ____                           
# |  _ \  ___| |__ (_) __ _ _ __   / ___|  ___ _ ____   _____ _ __ 
# | | | |/ _ \ '_ \| |/ _` | '_ \  \___ \ / _ \ '__\ \ / / _ \ '__|
# | |_| |  __/ |_) | | (_| | | | |  ___) |  __/ |   \ V /  __/ |   
# |____/ \___|_.__/|_|\__,_|_| |_| |____/ \___|_|    \_/ \___|_|   
#                                                                  
#  ____            _         ____             __ _       
# | __ )  __ _ ___(_) ___   / ___|___  _ __  / _(_) __ _ 
# |  _ \ / _` / __| |/ __| | |   / _ \| '_ \| |_| |/ _` |
# | |_) | (_| \__ \ | (__  | |__| (_) | | | |  _| | (_| |
# |____/ \__,_|___/_|\___|  \____\___/|_| |_|_| |_|\__, |
#                                                  |___/ 
# 
# Script by Christoph Daniel Miksche
# License: GNU General Public License
#
# Contact:
# >> http://cdm.webpage4.me
# >> Twitter: CMiksche
# >> GitHub: CMiksche
#
# Run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
# Include config
source ./config.sh
# Pause function
function pause(){
   read -p "$*"
}
# Update
apt-get update && apt-get upgrade -y
# Dist-Upgrade
apt-get dist-upgrade -y
# Install
# rkhunter, fail2ban and sudo are security tools
# nano = Editor
# htop = System monitoring
# figlet = ASCII Art
# screen = Additional terminal that continues running in the background
apt-get install openssh-server ca-certificates rkhunter fail2ban nano sudo htop whois curl nodejs figlet screen cron git ntp tar zip unzip -y

if ["$mailserver" == "yes"]
	then 
		apt-get purge exim4*
		mkdir ~/build ; cd ~/build
		wget -O - https://github.com/andryyy/mailcow/archive/v0.13.1.tar.gz | tar xfz -
		cd mailcow-*
		chmod +x /install.sh
		echo "
		Please edit the following file.
		More information: https://github.com/andryyy/mailcow
		"
		nano mailcow.config
		./install.sh
		pause 'Press [Enter] key to continue...'
fi

if ["$mailserver" == "postfix"]
	then 
		apt-get install postfix
fi

# Install Firewall
apt-get install ufw -y

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

# Message of the day
# Copy MotD
cp ./copy/motd /etc/motd
# Create ASCII Art from the hostname
figlet "$hostname" >> /etc/motd

# Change Hostname
rm -rf /etc/hostname
echo "$hostname" >> /etc/hostname
/etc/init.d/hostname.sh start

# Install FTP Service
if ["$ftpserver" == "vsftpd"]
	then 
		sudo apt-get install vsftpd
		# Allow FTP Commands
		sed -i "s/#write_enable=YES/write_enable=YES/g" /etc/vsftpd.conf
fi

# Install Webserver
# nginx
if ["$webserver" == "nginx"]
	then 
		sudo apt-get install nginx php5-fpm vsftpd
		# Go to "sites-available"
		cd /etc/nginx/sites-available
		# Copy example
		cp ./copy/nginxsite /etc/nginx/sites-available/"$website"
		# Change Name
		sed -i "s/yourdomain.com/$website/g" /etc/vsftpd.conf
		# Set link
		ln -s /etc/nginx/sites-available/"$website" /etc/nginx/sites-enabled/"$website"
		# Create dir for Website
		mkdir /var/www/html/$website
		# Create file for Website
		echo "<?php echo '<h1>Your new Website.</h1> <h3>Created by DebianServerBasicConfig.</h3>'; ?>" >> /var/www/html/$website/index.php
		# Restart nginx
		service nginx restart
		# Install Composer
		curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
fi
# apache
if ["$webserver" == "apache2"]
	then 
		sudo apt-get install apache2 php5
		# Install Composer
		curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
fi

# Install Database
if ["$database" == "mysql"]
	then 
		sudo apt-get install mysql-server phpmyadmin
		# Create Backup
		# Create dir
		mkdir /opt/basic_backup
		# Copy Backup File
		cp ./copy/createbackup.sh /opt/basic_backup/createbackup.sh
		# Change hostname in File
		sed -i "s/DBHOSTNAME/$hostname/g" /opt/basic_backup/createbackup.sh
		# Change database password in File
		sed -i "s/DBPASS/$databasepw/g" /opt/basic_backup/createbackup.sh
		# Change database user in File
		sed -i "s/DBUSER/$databaseuser/g" /opt/basic_backup/createbackup.sh
		# Make file executable
		chmod +x /opt/basic_backup/createbackup.sh
		# Write command in crontab
		echo "35 2    * * *	root   ./opt/basic_backup/createbackup.sh >> /opt/basic_backup/log.log 2>&1" >> /etc/crontab
fi 

# Install Let's Encrypt
if ["$letsencrypt" == "yes"]
	then
		# Install Let's Encrypt
		cd /opt
		git clone https://github.com/letsencrypt/letsencrypt
		cd letsencrypt
		./letsencrypt-auto --help
		# Create Certificate
		letsencrypt certonly --standalone -d $website -d www.$website
		# Renewal Cronjob
		echo "30 3    24 * *  root    service $webserver stop; cd /opt/letsencrypt; ./letsencrypt-auto renew; service $webserver start" >> /etc/crontab
fi

# Restart Services
/etc/init.d/ssh restart

# Inform the user
echo "

Hello,
the installation is finished."
if ["$database" == "mysql"]
	then 
		echo "
		Every day at 2:35 a backup of your database will created, Saturdays a backup of the dir /var/www will be created too.
		You can find your backups here: /var/www_backup/."
fi 
echo "
You should restart your Server now."
#	 _____       __ 
#	| ____|___  / _|
#	|  _| / _ \| |_ 
#	| |__| (_) |  _|
#	|_____\___/|_|  
#					
