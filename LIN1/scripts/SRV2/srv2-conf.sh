#! /bin/bash

adminSSHKey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGVi0MNingnvScAJJHb9+EYPngweg1PJfgUfsN5vwSS"

IPaddr="10.10.10.22/24"
IPgateway="10.10.10.11"

# NEXTCLOUD variables
SERVICE="nextcloud"
SRV_ADM="yann.fanha@eduvaud.ch"
DOC_ROOT="/var/www/html/nextcloud/"
SRV_NAME="srv-lin1-02.lin1.local"
SRV_IP="10.10.10.22"
SRV_ALIAS=$SRV_IP
CONF_FILE="/etc/apache2/sites-available/$SERVICE.conf"

LAN_NIC=$(ip -o -4 route show to default | awk '{print $5}')

apt-get update -y

# ---- SSH ----
mkdir -p /root/.ssh
echo $adminSSHKey >> /root/.ssh/authorized_keys
chmod -R go= /root/.ssh
chown -R root:root /root/.ssh

# IP conf
file="/etc/network/interfaces"
cat <<EOM >$file
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto $LAN_NIC
iface $LAN_NIC inet static
address $IPaddr
gateway $IPgateway
EOM

# nextcloud + apache2 configuration
# ATTENTION : Il faut créer la base de données manuellement

apt-get install apache2 libapache2-mod-php mariadb-server php-xml php-cli php-cgi php-mysql php-mbstring php-gd php-curl php-zip wget unzip -y

wget https://download.nextcloud.com/server/releases/latest.zip
unzip ~/latest.zip
mv ~/nextcloud /var/www/html/
chown -R www-data:www-data /var/www/html/nextcloud

file=/etc/apache2/sites-available/nextcloud.conf
cat <<EOM >$file
<VirtualHost *:80>
     ServerAdmin $SRV_ADM
     DocumentRoot $DOC_ROOT
     ServerName $SRV_NAME
     ServerAlias $SRV_ALIAS

     <Directory $DOC_ROOT>
          Options FollowSymlinks
          AllowOverride All
          Require all granted
     </Directory>

     ErrorLog ${APACHE_LOG_DIR}/error.log
     CustomLog ${APACHE_LOG_DIR}/access.log combined
    
     <Directory $DOC_ROOT>
            RewriteEngine on
            RewriteBase /
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule ^(.*) index.php [PT,L]
    </Directory>
</VirtualHost>
EOM

a2ensite $CONF_FILE
a2dissite 000-default.conf
a2enmod headers rewrite env dir mime
systemctl reload apache2

echo "=============================================="
echo "=============================================="
echo "Il est nécessaire de créer la base de données et son utilisateur manuellement"
echo "(nextclouddb - nextclouduser - password voulu"
echo "-"
echo -e "CREATE DATABASE nextclouddb;\nCREATE USER 'nextclouduser'@'localhost' IDENTIFIED BY 'Password';\nGRANT ALL ON nextclouddb.* TO 'nextclouduser'@'localhost';\nFLUSH PRIVILEGES;"
echo "=============================================="
echo "=============================================="