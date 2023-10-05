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

$NET_ADDR="10.10.10.0"
$DHCP_START_IP="10.10.10.110"
$DHCP_END_IP="10.10.10.119"
$SUBMASK="255.255.255.0"

srv01_ip="10.10.10.11"
srv02_ip="10.10.10.22"
srv03_ip="10.10.10.33"

rndc_DNS_FILE="/etc/bind/rndc.conf"
rndc_DHCP_FILE="/etc/dhcp/rndc.conf"

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
nameserver $DNSIPADDRESS

EOM

# Hostname

hostnamectl set-hostname $SRV01.$DOMAIN

# DNS
apt-get install bind9 -y

dns_file="/etc/bind/named.conf.options"
cat <<EOM >$dns_file
include "$rndc_DNS_FILE";
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
apt-get install isc-dhcp-server -y
dhcp_file="/etc/dhcp/dhcp.conf"
cat <<EOM >$dhcp_file

option domain-name "$DOMAIN";
option domain-name-servers $DNSIPADDRESS;

include "/etc/dhcp/rndc.conf";

ddns-updates on;
default-lease-time 600;
max-lease-time 7200;
ddns-update-style standard;
allow unknown-clients;
update-static-leases on;
ddns-rev-domainname "$REVERSE_ZONE";
do-forward-updates on;
authoritative;

zone $DOMAIN. {
 primary $DNSIPADDRESS;
 key rndc-key;
}

zone $REVERSE_ZONE. {
 primary $DNSIPADDRESS;
 key rndc-key;
}

subnet 10.10.10.0 netmask 255.255.255.0 {
        range $DHCP_START_IP $DHCP_END_IP;
        option routers $IPgateway;
        option domain-name "$DOMAIN";
        option domain-name-servers $DNSIPADDRESS;
}

EOM

# Dynamic DNS
cat <<EOM >$rndc_DNS_FILE
key "rndc-key" {
        algorithm <algo>;
        secret "<secret>";
};
EOM

rndc-confgen > /tmp/tmp_rndc.key

rndc_SECRET=$(grep -o 'secret "[^"]*"' /tmp/tmp_rndc.key | cut -d'"' -f2 | head -n 1)
rndc_ALGO=$(grep -o 'algorithm [^;]*;' /tmp/tmp_rndc.key | sed 's/algorithm //' | sed 's/;//' | head -n 1)
rm /tmp/tmp_rndc.key

sed -i "s|<algo>|$rndc_ALGO|g" $rndc_DNS_FILE
sed -i "s|<secret>|$rndc_SECRET|g" $rndc_DNS_FILE

cp $rndc_DNS_FILE $rndc_DHCP_FILE