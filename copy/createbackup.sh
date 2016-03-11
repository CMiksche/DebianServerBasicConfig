#!/bin/bash

# Times
date=`date -I`;
year=`date "+%G"`;
month=`date "+%m"`;
day=`date "+%d"`;
weekday=`date "+%a"`;

# Creating directories

if [ ! -d "/var/www_backup" ]
	then
		mkdir /var/www_backup
fi

if  [ ! -d "/var/www_backup/DBHOSTNAME" ]
	then
		mkdir /var/www_backup/DBHOSTNAME
fi

if [ ! -d "/var/www_backup/DBHOSTNAME/$year" ]
	then
		mkdir /var/www_backup/DBHOSTNAME/$year
fi

if [ ! -d "/var/www_backup/DBHOSTNAME/$year/$month" ]
	then
		mkdir /var/www_backup/DBHOSTNAME/$year/$month
fi

if [ ! -d "/var/www_backup/DBHOSTNAME/$year/$month/$day" ]
	then
		mkdir /var/www_backup/DBHOSTNAME/$year/$month/$day
fi

# Creating backup of data
if [ $weekday == "Sa" ] # If Saturday
	then
		tar -zcf /var/www_backup/DBHOSTNAME/$year/$month/$day/data.tgz /var/www
fi

# Create backup of database

mysqldump --all-databases -u DBUSER --password=DBPASS --events | gzip >/var/www_backup/DBHOSTNAME/$year/$month/$day/db.sql.gz
