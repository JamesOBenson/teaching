#!/bin/sh
#
# Wordpress Setup Script
#
# This script will install and configure WordPress on
# an Ubuntu 16.04 LTS VM

# If you want random passwords comment out the rootmysqlpass & wpmysqlpass and uncomment the generators...
rootmysqlpass=rootpassword
wpmysqlpass=wppassword
username=wordpress

# Generate Random passwords
#rootmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;
#wpmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;

###  DO NOT MODIFY BELOW THIS LINE ###
sudo apt-get install -y mysql-server

# Write passwords to file
sudo echo "Root MySQL Password: $rootmysqlpass" > /root/passwords.txt;
sudo echo "Wordpress MySQL Password: $wpmysqlpass" >> /root/passwords.txt;

# Update DB settings:
sudo /usr/bin/mysqladmin -u root -p$rootmysqlpass -h localhost create wordpress;
sudo /usr/bin/mysql -uroot -p$rootmysqlpass -e "CREATE USER $username@localhost IDENTIFIED BY '"$wpmysqlpass"'";
sudo /usr/bin/mysql -uroot -p$rootmysqlpass -e "CREATE USER $username@'%' IDENTIFIED BY '"$wpmysqlpass"'";
sudo /usr/bin/mysql -uroot -p$rootmysqlpass -e "GRANT ALL PRIVILEGES ON $username.* TO $username@localhost";
sudo /usr/bin/mysql -uroot -p$rootmysqlpass -e "GRANT ALL PRIVILEGES ON $username.* TO $username@'%'";
#sudo /usr/bin/mysql -uroot -p$rootmysqlpass -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost";


# TO find the port:
# mysql> SHOW GLOBAL VARIABLES LIKE 'PORT';
# netstat -tlnp

echo "[mysqld]" | sudo tee -a /etc/mysql/my.cnf
echo "bind-address = 0.0.0.0" | sudo tee -a /etc/mysql/my.cnf
# add the following two lines to: /etc/mysql/my.cnf
# [mysqld]
# bind-address = 0.0.0.0
sudo service mysql restart
