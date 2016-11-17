#!/bin/sh
#
# Wordpress Setup Script
#
# This script will install and configure WordPress on
# an Ubuntu 16.04 LTS VM

# Note, these are your passwords:
# rootmysqlpass=rootpassword
# wpmysqlpass=wppassword
# username=wordpress

sudo apt-get install -y mysql-server

# Update DB settings:
sudo /usr/bin/mysqladmin -u root -prootpassword -h localhost create wordpress;
sudo /usr/bin/mysql -uroot -prootpassword -e "CREATE USER wordpress@localhost IDENTIFIED BY 'wppassword'";
sudo /usr/bin/mysql -uroot -prootpassword -e "CREATE USER wordpress@'%' IDENTIFIED BY 'wppassword'";
sudo /usr/bin/mysql -uroot -prootpassword -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost";
sudo /usr/bin/mysql -uroot -prootpassword -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@'%'";


# TO find the port:
# mysql> SHOW GLOBAL VARIABLES LIKE 'PORT';
# netstat -tlnp

echo "[mysqld]" | sudo tee -a /etc/mysql/my.cnf
echo "bind-address = 0.0.0.0" | sudo tee -a /etc/mysql/my.cnf
# add the following two lines to: /etc/mysql/my.cnf
# [mysqld]
# bind-address = 0.0.0.0
sudo service mysql restart
