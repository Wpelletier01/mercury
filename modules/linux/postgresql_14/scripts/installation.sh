#!/bin/bash

source $(dirname "$0")/../lib/lib.sh


_read() {

    case "${1}" in 


        enable-service)
            systemctl list-dependencies multi-user.target | grep -i postgres &>/dev/null

            if [ $? -eq 0 ]; then 
                echo "1"
            else 
                echo "0"
            fi 

            ;;
        *)  
            echoErr "Argument $1 pas pris en charge"
            ;;
    esac 


}


_change() {

    case "${1}" in 

        enable-service)
            systemctl enable postgresql-14
            ;;
        *)  
            echoErr "Argument $1 pas pris en charge"
            ;;
    esac 
}


if [ "$1" == "change" ]; then 
    shift
    _change $@
elif [ "$1" == "read" ]; then 
    shift
    _read $@
fi