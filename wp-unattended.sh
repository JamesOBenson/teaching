#!/bin/sh
#
# Wordpress Setup Script
#
# This script will install and configure WordPress on
# an Ubuntu 16.04 LTS VM

# Generate root and WordPress mysql passwords

echo "What is the DB's IP Address?"
read DB_IP
echo "The MySQL Server is located at: $DB_IP"

rootmysqlpass=rootpassword
wpmysqlpass=wppassword
username=wordpress
#rootmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;
#wpmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;

apt-get install -y apache2 libapache2-mod-php php-mysql unzip;

# Download & uncompress wordpress
wget https://wordpress.org/latest.zip -O /tmp/wordpress.zip;
cd /tmp/;
unzip /tmp/wordpress.zip;

# Configure Wordpress
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php;
# sed -i "s/'DB_NAME', 'database_name_here'/'DB_NAME', 'wordpress'/g" /tmp/wordpress/wp-config.php;
# sed -i "s/'DB_USER', 'username_here'/'DB_USER', 'wordpress'/g" /tmp/wordpress/wp-config.php;
# sed -i "s/'DB_PASSWORD', 'password_here'/'DB_PASSWORD', '$wpmysqlpass'/g" /tmp/wordpress/wp-config.php;
sed -i "s/database_name_here/$username/g" /tmp/wordpress/wp-config.php;
sed -i "s/username_here/$username/g" /tmp/wordpress/wp-config.php;
sed -i "s/password_here/$wpmysqlpass/g" /tmp/wordpress/wp-config.php;
sed -i "s/localhost/$DB_IP/g" /tmp/wordpress/wp-config.php;
sed -i "/define('AUTH_KEY',/,+8d" /tmp/wordpress/wp-config.php;
sh -c 'curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /tmp/wordpress/wp-config.php;'

sudo cp -Rf /tmp/wordpress/* /var/www/html/.;
sudo rm -f /var/www/html/index.html;
sudo chown -Rf www-data:www-data /var/www/html;
sudo a2enmod rewrite;
sudo service apache2 restart;
