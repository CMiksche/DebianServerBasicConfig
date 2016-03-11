#!/bin/bash
#
# Script by Christoph Daniel Miksche
# License: GNU General Public License
#
# Contact:
# >> http://cdm.webpage4.me
# >> Twitter: CMiksche
# >> GitHub: CMiksche
#
# The Port SSH will be available
sshport="62688"
# Default User
defaultuser=""
# Default User Password
defaultpass=""
# Your E-Mail-Adress
systemmail="webmaster@yourdomain.com"
# Your preferred hostname
hostname="myServer"
# FTP-Server
# Options: vsftpd, any other word (= no FTP-Service)
ftpserver="vsftpd"
# Webserver
# Options: apache, nginx, any other word (= no Webserver)
webserver="nginx"
# Name of your Website
# Only needed if you use a webserver
website="yourdomain.com"
# Database
# Options: mysql, any other word (= no Database)
database="mysql"
# Password for Database User
# Only needed if you use a database
databasepw=""
# User for Database (Standard: root)
# Only needed if you use a database
databaseuser="root"

# ToDo:
# - Change Password of the "root"-User
# - Add mailserver option
