#!/usr/bin/env bash

ip=$1
serverName=$2
nextcloudUser=$3
nextcloudUserPsd=$4

db="nextcloud"

if [[ "$#" -ne 4 ]]; then
        echo "$0 <ip> <serverName> <nextcloud_db_user> <nextcloud_db_user_password>"
        exit 0
fi


apt update & apt upgrade -y
apt install apache2 mariadb-server mariadb-client unzip wget -y
systemctl start apache2

apt install libapache2-mod-php php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-intl php-curl php-xml php-mbstring php-bcmath php-gmp php-imagick -y

systemctl restart php8.2-fpm

wget  https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip -d /var/www/
chown -R www-data:www-data /var/www/nextcloud

mysql -u root -e "
	CREATE DATABASE $db;
	CREATE USER '$nextcloudUser'@'localhost' IDENTIFIED BY '$nextcloudUserPsd';
	GRANT ALL ON $db.* TO '$nextcloudUser'@'localhost';
	FLUSH PRIVILEGES;
 "

file="/etc/apache2/sites-available/nextcloud.conf"
cat <<EOM >$file
<VirtualHost *:80>
     DocumentRoot /var/www/nextcloud
     ServerName $serverName
     ServerAlias $ip

    <Directory /var/www/nextcloud>
         Options FollowSymlinks
         AllowOverride All
         Require all granted
     </Directory>

ErrorLog \${APACHE_LOG_DIR}/${serverName}_error2024.log

CustomLog \${APACHE_LOG_DIR}/${serverName}_access2024.log combined

</VirtualHost>
EOM

ln -s "/etc/apache2/sites-available/nextcloud.conf" "/etc/apache2/sites-enabled/nextcloud.conf"

a2enmod rewrite

systemctl restart apache2

rm -f $0