#!/bin/bash

source $(dirname "$0")/../lib/lib.sh


_read() {

    
    dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' xserver-xorg*  &>/dev/null

    if [ $? -eq 1 ]; then 
        echo "0" # n'est pas installer
    
    else 
        echo "1" # est installer
    fi 


}


_change() {
    
    apt -qq purge xserver-xorg* -y &>/dev/null
    
}


root_require

if [ "$1" == "change" ]; then 
    shift
    _change $@
elif [ "$1" == "read" ]; then 
    shift
    _read $@
fi