#!/bin/bash

source $(dirname "$0")/../lib/lib.sh

_read() {


    if [ $1 == "send-redirects" ]; then

        exec1=$(sysctl net.ipv4.conf.all.send_redirects |   awk -F' ' '{print $3}')
        exec2=$(sysctl net.ipv4.conf.default.send_redirects |   awk -F' ' '{print $3}')
        
        if [[ "$exec1" == "0"  || "$exec2" == "0" ]]; then
            echo "0"
        else 
            echo "1"
        fi


    elif [ $1 == "ip-forwarding" ]; then

        exec1=$(sysctl net.ipv4.ip_forward |   awk -F' ' '{print $3}')
        exec2=$(sysctl net.ipv6.conf.all.forwarding |   awk -F' ' '{print $3}')

        if [[ $exec1 -eq 0  || $exec2 -eq 0 ]]; then
            echo "0"
        else 
            echo "1"
        fi

    else 
        echoErr "Valeur de kernel pas pris en charge: $1"
    fi


}


_change() {

    if [ "$1" == "send-redirects" ]; then
        
        if [ "$2" != "0" ] && [ "$2" != "1" ] ; then
            echoErr "Valeur bolean attendu mais recu: $2"
        fi 

        echo "net.ipv4.conf.all.send_redirects = $2"  > /etc/sysctl.d/90-send-redirect.conf
        echo "net.ipv4.conf.default.send_redirects = $2"  >> /etc/sysctl.d/90-send-redirect.conf

    elif [ "$1" == "ip-forwarding" ]; then
        if [ "$2" != "0" ] && [ "$2" != "1" ]; then
            echoErr "Valeur bolean attendu mais recu: $2"
        fi 
        
        echo "net.ipv4.ip_forward = $2" > /etc/sysctl.d/90-ipforward.conf
        echo "net.ipv6.conf.all.forwarding = $2" >> /etc/sysctl.d/90-ipforward.conf
    else 
        echoErr "Valeur de kernel pas pris en charge: $1"
    fi

    sysctl --system &>/dev/null
}

root_require

if [ "$1" == "change" ]; then 
    shift
    _change $@
elif [ "$1" == "read" ]; then 
    shift
    _read $@
fi
