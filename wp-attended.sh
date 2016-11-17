#!/bin/sh
#
# Wordpress Setup Script
#
# This script will install and configure WordPress on
# an Ubuntu 16.04 LTS VM

apt-get install -y apache2 libapache2-mod-php php-mysql unzip;

# Download & uncompress wordpress
wget https://wordpress.org/latest.zip -O /tmp/wordpress.zip;
cd /tmp/;
unzip /tmp/wordpress.zip;

# Configure Wordpress
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php;

sudo sh -c 'curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /tmp/wordpress/wp-config.php;'

# go to /tmp/wordpress/wp-config.php
# Update the following fields:
# database_name_here
# username_here
# password_here
# localhost
# delete AUTH_KEY (8 lines worth)


sudo cp -Rf /tmp/wordpress/* /var/www/html/.;
sudo rm -f /var/www/html/index.html;
sudo chown -Rf www-data:www-data /var/www/html;
sudo a2enmod rewrite;
sudo service apache2 restart;
