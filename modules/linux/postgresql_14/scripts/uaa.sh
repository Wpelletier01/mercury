#!/bin/bash

source $(dirname "$0")/../lib/lib.sh

_read() {
    
    case "${1}" in

        set-user)
            ;;

        *)  
            echoErr "valeur pas pris en charge dans section uaa: ${1}"
            ;;
    esac

}


_change() {
    
    case "${1}" in

        set-user)
            ;;

        *)  
            echoErr "valeur pas pris en charge dans section uaa: ${1}"
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