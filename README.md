### Debian Server Basic Config - Bash Script

Author: Christoph Daniel Miksche

License: GNU General Public License

Version: 0.2 (untested alpha)

This is a bash script for setting the basic configuration of a debian based server.

Variables can be put / set in the "config.sh" file.

### Features:
* Update of installed packages
* Install of following packages: ufw rkhunter fail2ban nano sudo htop whois curl nodejs figlet screen cron ntp tar zip unzip
* Sets a cron for daily package update
* Install and basic configuration of the firewall ufw
* Creates new default user
* Disable of ssh-root-login
* Changes the default ssh port
* Install of the FTP Service, Webserver and Database
* Creates a simple message of the day with warnings for unauthorized user
* Creates a vHost for your Website
