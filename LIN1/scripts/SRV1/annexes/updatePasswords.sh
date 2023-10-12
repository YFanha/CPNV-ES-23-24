LDAP_BASE="dc=lin1,dc=local"
LdapAdminCNString="cn=admin,$LDAP_BASE"
LDAPPWD="LIL-fesm-zont"
USRPWD='Pa$$w0rd'

ldappasswd -s "$USRPWD" -D "$LdapAdminCNString" -x "uid=man1,ou=users,$LDAP_BASE" -w $LDAPPWD
ldappasswd -s "$USRPWD" -D "$LdapAdminCNString" -x "uid=man2,ou=users,$LDAP_BASE" -w $LDAPPWD
ldappasswd -s "$USRPWD" -D "$LdapAdminCNString" -x "uid=ing1,ou=users,$LDAP_BASE" -w $LDAPPWD
ldappasswd -s "$USRPWD" -D "$LdapAdminCNString" -x "uid=ing2,ou=users,$LDAP_BASE" -w $LDAPPWD
ldappasswd -s "$USRPWD" -D "$LdapAdminCNString" -x "uid=dev1,ou=users,$LDAP_BASE" -w $LDAPPWD