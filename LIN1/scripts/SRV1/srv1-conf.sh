#! /bin/bash

IPaddr="10.10.10.11/24"
IPgateway="10.10.10.11"
DNSIPADDRESS='10.10.10.11'
DOMAIN='lin1.local'
FORWARDERS="192.168.67.2"
REVERSE_ZONE="10.10.10.in-addr.arpa"

SRV01='srv-lin1-01'
SRV02='srv-lin1-02'
SRV03='nas-lin1-01'

srv01_ip="10.10.10.11"
srv02_ip="10.10.10.22"
srv03_ip="10.10.10.33"

# Interface réseau WAN
WAN_NIC=$(ip -o -4 route show to default | awk '{print $5}')

# Interface réseau LAN
LAN_NIC=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2a;getline}' | grep -v $WAN_NIC)

apt-get update -y

# ---- SSH ----
mkdir -p /root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGVi0MNingnvScAJJHb9+EYPngweg1PJfgUfsN5vwSS" >> /root/.ssh/authorized_keys
chmod -R go= /root/.ssh
chown -R root:root /root/.ssh

# IP conf
net_FILE="/etc/network/interfaces"
cat <<EOM >$net_FILE

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The WAN network interface
auto $WAN_NIC
iface $WAN_NIC inet dhcp

# The LAN network interface
auto $LAN_NIC
iface $LAN_NIC inet static
address $IPaddr

EOM

# Transformer notre serveur en "passerelle"
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

apt-get install iptables iptables-persistent -y
iptables -t nat -A POSTROUTING -o $WAN_NIC -j MASQUERADE
iptable-save > /etc/iptables/rules.v4

 # Prevent the DHCP client from rewriting the resolv.conf file
echo 'make_resolv_conf() { :; }' > /etc/dhcp/dhclient-enter-hooks.d/leave_my_resolv_conf_alone
chmod 755 /etc/dhcp/dhclient-enter-hooks.d/leave_my_resolv_conf_alone

# Resolv.conf
resolve_FILE="/etc/resolv.conf"
cat <<EOM >$resolve_FILE

domain $DOMAIN
search $DOMAIN
nameserver $srv01_ip

EOM

# Hostname

hostnamectl set-hostname $SRV01.$DOMAIN

# DNS
apt-get install bind9 -y

dns_file="/etc/bind/named.conf.options"
cat <<EOM >$dns_file
controls {
        inet 127.0.0.1 allow { 127.0.0.1; } keys { rndc-key; };
};
options {
        directory "/var/cache/bind";

        forwarders {
                $FORWARDERS;
        };
        
        dnssec-validation no;

        listen-on-v6 { any; };
};
EOM

dns_file="/etc/bind/named.conf.local"
cat <<EOM >$dns_file
zone "$DOMAIN" {
        type master;
        file "/var/lib/bind/zones/db.$DOMAIN";
        allow-update { key rndc-key; };
};

zone "$REVERSE_ZONE" {
        type master;
        file "/var/lib/bind/zones/db.$REVERSE_ZONE";
        allow-update { key rndc-key; };
};
EOM

...

# DHCP
