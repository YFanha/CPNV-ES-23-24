#! /bin/bash

apt update -y
apt install git -y
apt update -y
apt install libz-dev libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext cmake gcc -y

git clone https://github.com/XXXXXXX/Lin1.git

chmod +x Lin1/debianInstall/testEnvironnement.sh

cd Lin1/debianInstall/

./testEnvironnement.sh

cd ../../

rm -r Lin1

reboot