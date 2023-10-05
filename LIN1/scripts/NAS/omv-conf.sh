#! /bin/bash


# OpenMediaVault commands

# ---- SSH ----
mkdir -p /root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGVi0MNingnvScAJJHb9+EYPngweg1PJfgUfsN5vwSS" >> /root/.ssh/authorized_keys
chmod -R go= /root/.ssh
chown -R root:root /root/.ssh

# ---- IP ----
file="/etc/network/interfaces
cat <<EOM >$file
source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug ens33
iface ens33 inet static
address 10.10.10.33/24
gateway 10.10.10.11

EOM

systemctl restart networking