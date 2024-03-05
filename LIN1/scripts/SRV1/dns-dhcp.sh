#! /bin/bash

IPaddr="192.168.15.10/24"
IPgateway="192.168.15.10"
DNSIPADDRESS="192.168.15.10"
DOMAIN='fanha.local'
FORWARDERS="8.8.8.8"
REVERSE_ZONE="192.168.15.in-addr.arpa"

SRV01='fdns'

NET_ADDR="192.168.15.0"
DHCP_START_IP="192.168.15.200"
DHCP_END_IP="192.168.15.254"
SUBMASK="255.255.255.0"

srv01_ip="192.168.15.10"

rndc_DNS_FILE="/etc/bind/rndc.conf"
rndc_DHCP_FILE="/etc/dhcp/rndc.conf"

# Interface réseau WAN
WAN_NIC=$(ip -o -4 route show to default | awk '{print $5}')

# Interface réseau LAN
LAN_NIC=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2a;getline}' | grep -v $WAN_NIC | sed 's/ //g')


apt-get update -y

# Prevent the DHCP client from rewriting the resolv.conf file
echo 'make_resolv_conf() { :; }' > /etc/dhcp/dhclient-enter-hooks.d/leave_my_resolv_conf_alone
chmod 755 /etc/dhcp/dhclient-enter-hooks.d/leave_my_resolv_conf_alone


# ---- DNS ----
echo "====== INSTALLING BIND ======"
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

mkdir -p /var/lib/bind/zones

ORIGIN='$ORIGIN'
TTL='$TTL'

zoneDirecte="/var/lib/bind/zones/db.$DOMAIN"
cat <<EOM >$zoneDirecte
$ORIGIN .
$TTL 86400      ; 1 day
$DOMAIN IN      SOA     $SRV01.$DOMAIN. root.$DOMAIN. (
                        12         ; serial
                        604800     ; refresh (1 week)
                        86400      ; retry (1 day)
                        2419200    ; expire (4 weeks)
                        86400      ; minimum (1 day)
                        )
        NS      $DOMAIN.
        A       $srv01_ip
$ORIGIN $DOMAIN.
fdns     A       $srv01_ip
dns      CNAME   $SRV01
EOM

zoneInverse="/var/lib/bind/zones/db.$REVERSE_ZONE"
cat <<EOM >$zoneInverse
$ORIGIN .
$TTL 86400      ; 1 day
@       IN      SOA     $SRV01.$DOMAIN. root.$DOMAIN. (
                        9          ; serial
                        604800     ; refresh (1 week)
                        86400      ; retry (1 day)
                        2419200    ; expire (4 weeks)
                        86400      ; minimum (1 day)
                        )
                        NS      lin1.local.
$ORIGIN $REVERSE_ZONE.
10      PTR     $SRV01.
EOM

# Update Resolv.conf
resolve_FILE="/etc/resolv.conf"
cat <<EOM >$resolve_FILE

domain $DOMAIN
search $DOMAIN
nameserver $DNSIPADDRESS

EOM


# ---- DHCP ----
echo "====== INSTALLING isc-dhcp-server ======"
apt-get install isc-dhcp-server -y
dhcp_file="/etc/dhcp/dhcpd.conf"
cat <<EOM >$dhcp_file

option domain-name "$DOMAIN";
option domain-name-servers $DNSIPADDRESS;

include "$rndc_DHCP_FILE";

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

subnet 192.168.15.0 netmask 255.255.255.0 {
        range $DHCP_START_IP $DHCP_END_IP;
        option routers $IPgateway;
        option domain-name "$DOMAIN";
        option domain-name-servers $DNSIPADDRESS;
}

EOM

echo "INTERFACESv4=$LAN_NIC" > /etc/default/isc-dhcp-server

# ---- Dynamic DNS - RNDC KEY ----
# -> Générer la clé dans un fichier temporaire et update celui du DNS (+ Copie dans le dossier /etc/dhcp/)
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

# ---- Restart all services ----
systemctl restart named
systemctl restart isc-dhcp-server.service

chown -R bind:bind /var/lib/bind/zones