#!/usr/bin/bash

file="/home/$USER/.bash_aliases"
cat >> $file << EOL
alias ll='ls -l'
alias la='ls -la'
alias ct='clear && tree'
alias cta='clear && tree -a'
alias p='cat'
alias h='head'
EOL


rm $0
