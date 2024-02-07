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
apt install nginx mariadb-server mariadb-client unzip wget -y
systemctl start nginx

apt install php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-intl php-curl php-xml php-mbstring php-bcmath php-gmp -y

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


file="/etc/nginx/conf.d/nextcloud.conf"
cat <<EOM >$file
server {
  listen 80;
  server_name $ip $serverName;
  root /var/www/nextcloud;
  index index.php index.html;
  charset utf-8;
  location / {
    try_files $uri $uri/ /index.php?$args;
  }
  location ~ .php$ {
    fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
  }
}
EOM

rm -f $0