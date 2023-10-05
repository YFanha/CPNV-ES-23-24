#! /bin/bash

IPaddr="10.10.10.22/24"
IPgateway="10.10.10.11"

LAN_NIC=$(ip -o -4 route show to default | awk '{print $5}')

apt-get update -y

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

# nextcloud download
wget https://raw.githubusercontent.com/YFanha/CPNV-ES-23-24/main/LIN1/scripts/SRV2/nextcloud.sh
chmod +x nextcloud.sh
./nextcloud.sh
rm nextcloud.sh