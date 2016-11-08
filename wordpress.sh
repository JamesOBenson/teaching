#!/bin/bash
username=wordpress
dbusername=wordpressuser
KEYPAIR=myprivatekey

IPADDR="10.245.135.22"
#IPADDR=`curl -s http://icanhazip.com` > /dev/null

mysqlpassword="root"

##############################################################
####             DO NOT MODIFY BELOW THIS LINE            ####
##############################################################

#  This is for the controller (where this script is running)
function setup_client_os () {
 sudo pip install python-openstackclient
}

function install_user() {
if [ $(id -u) -eq 0 ]; then
	read -p "Enter username (default: wordpress): " username
           if [[ -z "${username}" ]]; 
              then username='wordpress' 
           fi
        egrep "^$username" /etc/passwd >/dev/null
        if [ $? -eq 0 ]; then
                echo "$username exists!"
                exit 1
	fi
        read -s -p "Enter password (default: WPpassword) : " password
           if [[ -z "${password}" ]]; 
              then password='WPpassword' 
           fi
#	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		sudo useradd -m -p $pass $username
		usermod -aG sudo $username
		[ $? -eq 0 ] && echo "User has been added to system and promoted to sudo user!" || echo "Failed to add a user!"
#	fi
else
	echo "Only root may add a user to the system"
	exit 2
fi
}

function Apache () {
  echo ""
  echo ""
  echo "Installing Apache Software"
  echo ""
  echo ""
# Install LAMP stack
  sudo apt-get -y update
  sudo apt-get install -y apache2
  sudo apache2ctl configtest
  sudo echo "ServerName $IPADDR" >> /etc/apache2/apache2.conf
  sudo apache2ctl configtest
  echo "DEBUG VERIFY :  Syntax OK"
  sleep 5
  sudo systemctl restart apache2
#  sudo ufw allow 'Apache Full'"
  sudo ufw allow proto tcp from any to any port 80,443
  echo "RESULT:  PLEASE VERIFY YOUR WEBSITE CAN BE VIEWED AT: http://$IPADDR"
}


function MySQL_Server () {
  echo ""
  echo ""
  echo "DEBUG: INSTALLING MySQL Server"
  echo ""
  echo ""
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysqlpassword"
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysqlpassword"

#  echo 'mysql-server mysql-server/root_password password $mysqlpassword' | sudo debconf-set-selections
#  echo 'mysql-server mysql-server/root_password_again password $mysqlpassword' | sudo debconf-set-selections
  export DEBIAN_FRONTEND=noninteractive; sudo apt-get install -y mysql-server
  read -p "Do you want to do a secure (manual) mysql installation?   (Default: no) " -n 1 -r  mysqlsecureinstall
  case "$mysqlsecureinstall" in 
    y|Y ) 
       echo ""
       echo "beginning installation...."
       sleep 1
       sudo mysql_secure_installation
       ;;
    * ) 
       echo ""
       echo "skipping installation..."
       sleep 1
       ;;
   esac
#  sudo mysql_secure_installation <<EOF
#n
#root
#root
#y
#y
#y
#y
#EOF
#"
}

function PHP () {
  echo ""
  echo ""
  echo "DEBUG: INSTALLING PHP"
  echo ""
  echo ""
  sudo apt-get install -y php libapache2-mod-php php-mcrypt php-mysql
  sudo sed 's/php/html/' /etc/apache2/mods-enabled/dir.conf
  sudo sed 's/html/php/' /etc/apache2/mods-enabled/dir.conf
#  scp vars/info.php ubuntu@$IPADDR:/tmp/info.php
  sudo cp vars/info.php /var/www/html/info.php
#  sudo cp /tmp/info.php /var/www/html/info.php
  sudo systemctl restart apache2
  echo "RESULT:  PLEASE VERIFY YOUR WEBSITE CAN BE VIEWED AT: http://$IPADDR/info.php"
}

function SSL_Keys () {
  echo ""
  echo ""
  echo "DEBUG:  SETTING UP SSL KEYS"
  echo ""
  echo ""
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -new \
    -subj "/C=US/ST=Texas/L=SanAntonio/O=UTSA/CN=$IPADDR" \
    -keyout /etc/ssl/private/apache-selfsigned.key  -out /etc/ssl/certs/apache-selfsigned.crt
  sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
#  scp -i $SSH_PATH /home/ubuntu/TSERI/openstack_data_processing/include/krb5.conf $SSH_USER_NAME@$EDGE_IP:/tmp/krb5.conf "
#  scp ssl-params.conf ubuntu@$IPADDR:/tmp/ssl-params.conf
  cp vars/ssl-params.conf /etc/apache2/conf-available/ssl-params.conf
#  sudo cp /tmp/ssl-params.conf /etc/apache2/conf-available/ssl-params.conf
  sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bak
#  scp default-ssl.conf ubuntu@$IPADDR:/tmp/default-ssl.conf
  cp vars/default-ssl.conf /tmp/default-ssl.conf
  sudo sed -i "s/IPADDR/$IPADDR/" /tmp/default-ssl.conf
  sudo cp /tmp/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
  sudo sed -i '2i        Redirect permanent "/" "https://IPADDR/"' /etc/apache2/sites-available/000-default.conf
  sudo sed -i "s/IPADDR/$IPADDR/" /etc/apache2/sites-available/000-default.conf
  sudo ufw allow in 'Apache Full'
  sudo a2enmod ssl
  sudo a2enmod headers
  sudo a2ensite default-ssl
  sudo a2enconf ssl-params
  sudo apache2ctl configtest
  sudo systemctl restart apache2
  echo "RESULT:  PLEASE VERIFY YOUR WEBSITE CAN BE VIEWED AT: https://$IPADDR"
}

function Wordpress () {
  mysql -u root -proot --execute="CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci; "
  mysql -u root -proot --execute="GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY '$mysqlpassword';FLUSH PRIVILEGES;"
  sudo apt-get install -y php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc
  sudo systemctl restart apache2
  cat << EOF >> /etc/apache2/apache2.conf
<Directory /var/www/html/>
AllowOverride All
</Directory>
EOF
  sudo a2enmod rewrite
  sudo apache2ctl configtest
  sudo systemctl restart apache2
  cd /tmp
  curl -O https://wordpress.org/latest.tar.gz
  tar xzvf latest.tar.gz
touch /tmp/wordpress/.htaccess
chmod 660 /tmp/wordpress/.htaccess
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
mkdir /tmp/wordpress/wp-content/upgrade
sudo cp -a /tmp/wordpress/. /var/www/html
sudo chown -R $username:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod g+s {} \;
sudo chmod g+w /var/www/html/wp-content
sudo chmod -R g+w /var/www/html/wp-content/themes
sudo chmod -R g+w /var/www/html/wp-content/plugins
sudo sed -i "s/define('AUTH_KEY',/,+8d" /var/www/html/wp-config.php
sudo sh -c 'curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wp-config.php'
sudo sed -i "s/database_name_here/wordpress/g" /var/www/html/wp-config.php
sudo sed -i "s/username_here/$username/g" /var/www/html/wp-config.php
sudo sed -i "s/password_here/$mysqlpassword/g" /var/www/html/wp-config.php
sudo echo "define('FS_METHOD', 'direct');" >> /var/www/html/wp-config.php

}

function uninstall () {
  sudo apt-get --purge remove mysql-server mysql-common mysql-client php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc apache2 php libapache2-mod-php php-mcrypt php-mysql
}


function cmd () {
  # Run custom command for each node in cluster
  CMD=$1
  echo "The command to run is --> [$CMD]"
#  ssh -i $SSH_PATH  ubuntu@$IPADDR $CMD
#  ssh ubuntu@$IPADDR $CMD
  $CMD
}

function usage () {
  echo ""
  echo "Missing paramter. Please Enter one of the following options"
  echo ""
  echo "Usage: $0 {Any of the options below}"
  echo ""
  echo "setup_client_os (needed only once)"
  echo "install_user"
  echo ""
  echo "PreReqs (Installs all of the steps below)"
  echo "  Apache"
  echo "  MySQL_Server"
  echo "  PHP"
  echo "  SSL_Keys"
  echo ""
  echo "Wordpress"

  echo "cmd"

}

function main () {
  echo ""
  echo "Welcome to WordPress Deploy Script"
  echo ""

 if [ -z $1 ]; then 
   usage
   exit 1
 fi

 case $1 in 
    "setup_client_os")
      setup_client_os
     ;;
    "MySQL_Server")
      MySQL_Server
    ;;
    "PHP")
      PHP
    ;;
    "SSL_Keys")
      SSL_Keys
    ;;
    "install_user")
      install_user
     ;;
    "Apache")
      Apache
     ;;
    "cmd")
      cmd
    ;;
    "PreReqs")
      Apache
      MySQL_Server
      PHP
      SSL_Keys
    ;;
    "Wordpress")
      Wordpress
    ;;
    *)
     usage
     exit 1
esac
}

main "$1"
