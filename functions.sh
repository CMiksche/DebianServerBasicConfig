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
# Pause function
function pause(){
   read -p "$*"
}
# Function for Installing Composer
function installcomposer(){
	# Install Composer
	curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
	# Write command in crontab
	echo "29 1    * * *	root   /usr/local/bin/composer self-update" >> /etc/crontab
}
# Function for Installing Bower
function installbower(){
	# Install Bower
	npm install -g bower
}
# Function to create database backups
function dbbackup(){
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
}
