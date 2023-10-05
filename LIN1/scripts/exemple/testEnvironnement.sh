#!/bin/bash
#
#Passerele par defaut
#Source : Noah Spurrier, StackOverFlow
#
BaseEnvGatewayDefault=$(ip route list | sed -n -e "s/^default.*[[:space:]]\([[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\).*/\1/p")

ping -c1 www.google.ch > /dev/null && BaseEnvGoogleTry=TRUE || BaseEnvGoogleTry=FALSE

while true; do
read -p "

Configuration actuelle :
-------------------------------

Votre passerelle par defaut : $BaseEnvGatewayDefault 

Reponse de Google.ch : $BaseEnvGoogleTry

-------------------------------

Voulez-vous continuer ? (o/N) " on

case $on in 
	[yY][eE][sS]|[yY][oO][uU][iI]|[oO] ) 
    chmod +x debianInstall.sh
    ./debianInstall.sh ;
		break;;
	[nN] ) echo exiting...;
		exit;;
	* ) echo invalid response;;
esac

done
