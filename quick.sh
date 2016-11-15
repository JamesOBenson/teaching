#!/bin/sh
#
# Wordpress Setup Script
#
# This script will install and configure WordPress on
# an Ubuntu 16.04 LTS VM

export DEBIAN_FRONTEND=noninteractive;

# Generate root and WordPress mysql passwords
rootmysqlpass=rootpassword
wpmysqlpass=wppassword
username=wordpress
#rootmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;
#wpmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;


# Write passwords to file
echo "Root MySQL Password: $rootmysqlpass" > /root/passwords.txt;
echo "Wordpress MySQL Password: $wpmysqlpass" >> /root/passwords.txt;


# Update Ubuntu
apt-get update;

# Install Apache/MySQL/PHP
#apt-get install -y mysql-server mysql-client;
#apt-get install -y apache2;
#apt-get install -y php7 php7-mysql php libapache2-mod-php php-mcrypt php-mysql;
apt-get install -y unzip;
apt-get install -y lamp-server^

# Download & uncompress wordpress
wget https://wordpress.org/latest.zip -O /tmp/wordpress.zip;
cd /tmp/;
unzip /tmp/wordpress.zip;

# Set up database user
/usr/bin/mysqladmin -u root -h localhost create wordpress;
/usr/bin/mysqladmin -u root -h localhost password $rootmysqlpass;
/usr/bin/mysql -uroot -p$rootmysqlpass -e "CREATE USER wordpress@localhost IDENTIFIED BY '"$wpmysqlpass"'";
/usr/bin/mysql -uroot -p$rootmysqlpass -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost";

# Configure Wordpress
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php;
# sed -i "s/'DB_NAME', 'database_name_here'/'DB_NAME', 'wordpress'/g" /tmp/wordpress/wp-config.php;
# sed -i "s/'DB_USER', 'username_here'/'DB_USER', 'wordpress'/g" /tmp/wordpress/wp-config.php;
# sed -i "s/'DB_PASSWORD', 'password_here'/'DB_PASSWORD', '$wpmysqlpass'/g" /tmp/wordpress/wp-config.php;
sed -i "s/database_name_here/$username/g" /tmp/wordpress/wp-config.php;
sed -i "s/username_here/$username/g" /tmp/wordpress/wp-config.php;
sed -i "s/password_here/$wpmysqlpass/g" /tmp/wordpress/wp-config.php;
sed -i "/define('AUTH_KEY',/,+8d" /tmp/wordpress/wp-config.php;
sh -c 'curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /tmp/wordpress/wp-config.php;'


# Deploy Wordpress website
cp -Rf /tmp/wordpress/* /var/www/html/.;
rm -f /var/www/html/index.html;
chown -Rf www-data:www-data /var/www/html;
a2enmod rewrite;
service apache2 restart;

echo "Congrats, please go to your website and finish setting up wordpress!"
