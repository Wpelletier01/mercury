#!/bin/bash

source $(dirname "$0")/../lib/lib.sh


CONF_FILE="/etc/ssh/sshd_config"
CONF_DIR="/etc/ssh/sshd_config.d"


# arg 1: file
# arg 2: valeur
# arg 3: parametre
__update_file() {

    if [ ! -z "$(grep -P "^[\s]*$3" $1)" ]; then

        if [ "$2" == "0" ]; then
            sed -i "s/^\s*$3 yes/$3 no/" $1
            echo 1
        elif [ "$2" == "1" ]; then
            sed -i "s/^\s*$3 no/$3 yes/" $1
            echo 1
        else
            echoErr "s'attend a recevoir un boolean: $2"
        fi
    else
        echo 0
    fi 

}


# arg 1: value
# arg 2: parameter
__update() {

    found=0
    for file in $CONF_DIR/*; do
        
        if [ "$(__update_file $file $1 $2 )" == "1" ]; then
            found=1
            break
        fi
    done

    if [ $found -ne 1 ]; then
        
        if [ $(__update_file $CONF_FILE $1 $2 ) -ne 1 ]; then
            
            val=""
            if [ "$2" == "0" ]; then
                val="no"
            else
                val="yes"
            fi
            echo "$2 $val" >> $CONF_FILE
        fi
        
    fi


}


_read() {

    case "${1}" in

        x11-forwarding)
            
            shopt -s lastpipe
            sshd \
            -T \
            -C user=root \
            -C host="$(hostname)" \
            -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | \
            grep x11forwarding | \
            awk '{print $2}' | \
            read output

            if [ "$output" == "yes" ]; then
                echo "1"
            elif [ "$output" == "no" ]; then
                echo "0"
            fi

            ;;

        empty-password)

            shopt -s lastpipe
            sshd \
            -T \
            -C user=root \
            -C host="$(hostname)" \
            -C addr="$(grep $(hostname) \
            /etc/hosts | \
            awk '{print $1}')" | \
            grep permitemptypasswords | \
            awk '{print $2}' | \
            read output

            if [ "$output" == "yes" ]; then
                echo "1"
            elif [ "$output" == "no" ]; then
                echo "0"
            fi 

            ;;   
    
        *)

            echoErr "Valeur de sshd pas pris en charge: $1"
            ;;

    esac

}


_change() {
    
    case "${1}" in

        x11-forwarding)
            
            __update $2 "X11Forwarding"
            ;;

        empty-password)
            __update $2 "PermitEmptyPasswords"
            ;;   
    
        *)
            echoErr "Valeur de sshd pas pris en charge: $1"
            ;;

    esac
}


root_require

if [ "$1" == "change" ]; then 
    shift
    _change $@
    systemctl reload sshd

elif [ "$1" == "read" ]; then 
    shift
    _read $@
fi