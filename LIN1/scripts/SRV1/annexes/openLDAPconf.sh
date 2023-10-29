#! /bin/bash

LDAP_BASE="dc=lin1,dc=local"
LdapAdminCNString="cn=admin,$LDAP_BASE"
LDAPPWD="LIL-fesm-zont"
USRPWD='Pa$$w0rd'
DOMAIN="lin1.local"
LDAP_IP="10.10.10.11"
OU='lin1'


echo -e " \ 
slapd slapd/password2 password $LDAPPWD
slapd slapd/password1 password $LDAPPWD
slapd slapd/move_old_database boolean true
slapd shared/organization string $OU
slapd slapd/no_configuration boolean false
slapd slapd/purge_database boolean false
slapd slapd/domain string $DOMAIN
" | debconf-set-selections

export DEBIAN_FRONTEND=noninteractive

apt-get install slapd ldap-utils -y

mkdir /etc/ldap/content

LDAP_FILE="/etc/ldap/ldap.conf"
cat <<EOM >$LDAP_FILE
BASE	$LDAP_BASE
URI	ldap://$LDAP_IP
# ldap://ldap-provider.example.com:666

#SIZELIMIT	12
#TIMELIMIT	15
#DEREF		never

# TLS certificates (needed for GnuTLS)
TLS_CACERT	/etc/ssl/certs/ca-certificates.crt
EOM

systemctl restart slapd.service

LDAP_FILE="/etc/ldap/content/base.ldif"
cat <<EOM >$LDAP_FILE
dn: ou=users,$LDAP_BASE
objectClass: organizationalUnit
objectClass: top
ou: users

dn: ou=groups,$LDAP_BASE
objectClass: organizationalUnit
objectClass: top
ou: groups
EOM
 

LDAP_FILE="/etc/ldap/content/groups.ldif"
cat <<EOM >$LDAP_FILE
dn: cn=Managers,ou=groups,$LDAP_BASE
objectClass: top
objectClass: posixGroup
gidNumber: 20000

dn: cn=Ingenieurs,ou=groups,$LDAP_BASE
objectClass: top
objectClass: posixGroup
gidNumber: 20010

dn: cn=Devloppeurs,ou=groups,$LDAP_BASE
objectClass: top
objectClass: posixGroup
gidNumber: 20020
EOM

 

LDAP_FILE="/etc/ldap/content/users.ldif"
cat <<EOM >$LDAP_FILE
dn: uid=man1,ou=users,$LDAP_BASE
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: man1
userPassword: {crypt}x
cn: Man1
givenName: Man
sn: 1
loginShell: /bin/bash
uidNumber: 10000
gidNumber: 20000
displayName: Man 1
homeDirectory: /home/man1
mail: man1@$DOMAIN
description: Man 1 account 

dn: uid=man2,ou=users,$LDAP_BASE
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: man2
userPassword: {crypt}x
cn: Man2
givenName: Man
sn: 2
loginShell: /bin/bash
uidNumber: 10001
gidNumber: 20000
displayName: Man 2
homeDirectory: /home/man2
mail: man2@$DOMAIN
description: Man 2 account

dn: uid=ing1,ou=users,$LDAP_BASE
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: ing1
userPassword: {crypt}x
cn: Ing1
givenName: Ing
sn: 1
loginShell: /bin/bash
uidNumber: 10010
gidNumber: 20010
displayName: Ing 1
homeDirectory: /home/ing1
mail: ing1@$DOMAIN
description: Ing 1 account

dn: uid=ing2,ou=users,$LDAP_BASE
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: ing2
userPassword: {crypt}x
cn: Ing2
givenName: Ing
sn: 2
loginShell: /bin/bash
uidNumber: 10011
gidNumber: 20010
displayName: Ing 2
homeDirectory: /home/ing2
mail: ing2@$DOMAIN
description: Ing 2 account

dn: uid=dev1,ou=users,$LDAP_BASE
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: dev1
userPassword: {crypt}x
cn: Dev1
givenName: Dev
sn: 1
loginShell: /bin/bash
uidNumber: 10020
gidNumber: 20020
displayName: Dev 1
homeDirectory: /home/dev1
mail: dev1@$DOMAIN
description: Dev 1 account
EOM

 

LDAP_FILE="/etc/ldap/content/addtogroup.ldif"
cat <<EOM >$LDAP_FILE
dn: cn=Managers,ou=groups,$LDAP_BASE
changetype: modify
add: memberuid
memberuid: man1 

dn: cn=Managers,ou=groups,$LDAP_BASE
changetype: modify
add: memberuid
memberuid: man2 

dn: cn=Ingenieurs,ou=groups,$LDAP_BASE
changetype: modify
add: memberuid
memberuid: ing1 

dn: cn=Ingenieurs,ou=groups,$LDAP_BASE
changetype: modify
add: memberuid
memberuid: ing2 

dn: cn=Devloppeurs,ou=groups,$LDAP_BASE
changetype: modify
add: memberuid
memberuid: dev1
EOM

ldapadd -x -D "$LdapAdminCNString" -f /etc/ldap/content/base.ldif -w $LDAPPWD

ldapadd -x -D "$LdapAdminCNString" -f /etc/ldap/content/users.ldif -w $LDAPPWD

ldappasswd -s "$USRPWD" -D "$LdapAdminCNString" -x "uid=man1,ou=users,$LDAP_BASE" -w $LDAPPWD
ldappasswd -s "$USRPWD" -D "$LdapAdminCNString" -x "uid=man2,ou=users,$LDAP_BASE" -w $LDAPPWD
ldappasswd -s "$USRPWD" -D "$LdapAdminCNString" -x "uid=ing1,ou=users,$LDAP_BASE" -w $LDAPPWD
ldappasswd -s "$USRPWD" -D "$LdapAdminCNString" -x "uid=ing2,ou=users,$LDAP_BASE" -w $LDAPPWD
ldappasswd -s "$USRPWD" -D "$LdapAdminCNString" -x "uid=dev1,ou=users,$LDAP_BASE" -w $LDAPPWD

ldapadd -x -D "$LdapAdminCNString" -f /etc/ldap/content/groups.ldif -w $LDAPPWD

ldapmodify -x -D "$LdapAdminCNString" -f /etc/ldap/content/addtogroup.ldif -w $LDAPPWD


systemctl restart slapd
apt-get install ldap-account-manager -y