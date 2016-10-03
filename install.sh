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
# >> http://christoph.miksche.org
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
# Include functions
source ./functions.sh
# Update
apt update && apt upgrade -y
# Dist-Upgrade
apt dist-upgrade -y
# Install
# rkhunter, fail2ban and sudo are security tools
# nano = Editor
# htop = System monitoring
# figlet = ASCII Art
# screen = Additional terminal that continues running in the background
apt install openssh-server ca-certificates rkhunter fail2ban nano sudo htop whois curl nodejs figlet screen cron git ntp tar zip unzip -y

if [ $mailserver == "yes" ]
	then 
		apt purge exim4*
		apt install netcat -y
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

if [ $mailserver == "postfix" ]
	then 
		apt install postfix -y
fi

# Install Firewall
apt install ufw -y

# (Re-)Start
service ufw restart
service fail2ban restart
# Daily Update
su -c "echo -e \"#! /bin/sh\napt update && apt upgrade -y\" >> /etc/cron.daily/update && chmod a+x /etc/cron.daily/update"
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
cp copy/motd /etc/motd
# Create ASCII Art from the hostname
figlet "$hostname" >> /etc/motd

# Change Hostname
rm -rf /etc/hostname
echo "$hostname" >> /etc/hostname
/etc/init.d/hostname.sh start

# Install FTP Service
if [ $ftpserver == "vsftpd" ]
	then 
		sudo apt install vsftpd -y
		# Allow FTP Commands
		sed -i "s/#write_enable=YES/write_enable=YES/g" /etc/vsftpd.conf
fi

# Install Node.js
if [ $node == "yes" ]
	then 
		sudo apt install nodejs-legacy node npm -y
		npm install pm2 -g
fi

# Install Webserver
# nginx
if [ $webserver == "nginx" ]
	then 
		# Install PHP
		if [ $php == "yes" ]
			then 
				sudo apt install php5-fpm -y
		fi
		sudo apt install nginx vsftpd -y
		# Copy example
		cp copy/nginxsite /etc/nginx/sites-available/"$website"
		# Change Name
		sed -i "s/yourdomain.com/$website/g" /etc/nginx/sites-available/"$website"
		# Set link
		ln -s /etc/nginx/sites-available/"$website" /etc/nginx/sites-enabled/"$website"
		# Create dir for Website
		mkdir /var/www/html/$website
		# Create file for Website
		echo "<?php echo '<h1>Your new Website.</h1> <h3>Created by DebianServerBasicConfig.</h3>'; ?>" >> /var/www/html/$website/index.php
		# Delete old default file
		cp /etc/nginx/sites-available/default /etc/nginx/sites-available/OLD_default
		rm -rf /etc/nginx/sites-available/default
		rm -rf /etc/nginx/sites-enabled/default
		# Copy default example
		cp copy/nginxdefault /etc/nginx/sites-available/default
		# Set default link
		ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
		# Restart nginx
		service nginx restart
		# Install Composer
		installcomposer
fi
# apache
if [ $webserver == "apache2" ]
	then 
		sudo apt install apache2 php5 -y
		# Install Composer
		installcomposer
fi

# Install Database
if [ $database == "mysql" ]
	then 
		sudo apt install mysql-server phpmyadmin -y
		# Create Backup
		# Create dir
		mkdir /opt/basic_backup
		# Copy Backup File
		cp copy/createbackup.sh /opt/basic_backup/createbackup.sh
		# Change hostname in File
		sed -i "s/DBHOSTNAME/$hostname/g" /opt/basic_backup/createbackup.sh
		# Change database password in File
		sed -i "s/DBPASS/$databasepw/g" /opt/basic_backup/createbackup.sh
		# Change database user in File
		sed -i "s/DBUSER/$databaseuser/g" /opt/basic_backup/createbackup.sh
		# Make file executable
		chmod +x /opt/basic_backup/createbackup.sh
		# Write command in crontab
		echo "35 2    * * *	root    /opt/basic_backup/createbackup.sh" >> /etc/crontab
		if [ $webserver == "nginx" ]
			then 
			# website.com/phpmyadmin
			ln -s /usr/share/phpmyadmin /usr/share/nginx/html
			ln -s /usr/share/phpmyadmin /var/www/html
			php5enmod mcrypt
			# pma.website.com
			# Copy example
			cp copy/nginxpma /etc/nginx/sites-available/pma."$website"
			# Change Name
			sed -i "s/yourdomain.com/pma.$website/g" /etc/nginx/sites-available/pma."$website"
			# Set link
			ln -s /etc/nginx/sites-available/pma."$website" /etc/nginx/sites-enabled/pma."$website"
			service php5-fpm restart
			service nginx restart
		fi
fi 

# Install Let's Encrypt
if [ $letsencrypt == "yes" ]
	then
		# Add Backports
		echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
		sudo apt update
		# Install Let's Encrypt
		sudo apt install certbot -t jessie-backports
		# Stop webserver
		service "$webserver" stop
		# Create Certificate
		certbot certonly --standalone -d $website -d www.$website
		# Renewal Cronjob
		echo "30 3    24 * *  root    service $webserver stop; certbot renew; service $webserver start" >> /etc/crontab
		# Start webserver
		service "$webserver" start
fi

# Forward E-Mails to Systememail
echo "root: $systemmail" >> /etc/aliases

# Restart Services
/etc/init.d/ssh restart

# Inform the user
echo "

Hello,
the installation is finished."
if [ $database == "mysql" ]
	then 
		echo "
		Every day at 2:35 a backup of your database will created, Saturdays a backup of the dir /var/www will be created too.
		You can find your backups here: /var/www_backup/."
fi 
echo "
You should restart (reboot) your Server now."
#	 _____       __ 
#	| ____|___  / _|
#	|  _| / _ \| |_ 
#	| |__| (_) |  _|
#	|_____\___/|_|  
#					
