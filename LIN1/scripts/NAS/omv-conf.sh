#! /bin/bash

adminSSHKey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGVi0MNingnvScAJJHb9+EYPngweg1PJfgUfsN5vwSS"

IPaddr="10.10.10.33/24"
IPgateway="10.10.10.11"

LAN_NIC=$(ip -o -4 route show to default | awk '{print $5}')

apt-get update -y

# OpenMediaVault commands

# ---- SSH ----
mkdir -p /root/.ssh
echo $adminSSHKey >> /root/.ssh/authorized_keys
chmod -R go= /root/.ssh
chown -R root:root /root/.ssh

# ---- IP ----
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

systemctl restart networking