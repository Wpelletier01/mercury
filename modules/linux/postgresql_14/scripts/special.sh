#!/bin/bash

source $(dirname "$0")/../lib/lib.sh

_read() {

    case "${1}" in

        pgbackrest)
            
            pgbackrest  &>/dev/null
            
            ecode=$?

            # 127 peut dire command not found
            if [ $ecode -eq 1 ] || [ $ecode -eq 127 ]; then 
                echo "0"
            elif [ $ecode -eq 0 ]; then 
                echo "1"
            else
                echoErr "valeur innatendu: exit code $ecode"
            fi 

            ;;

        *)  
            echoErr "valeur pas pris en charge dans section special: ${1}"
            ;;
    esac
}


_change() {

    case "${1}" in

        pgbackrest)
            
            if [ "$2" == "1" ]; then 
                apt install pgbackrest -y &>/dev/null 
            elif [ "$2" == "0" ]; then
                apt purge pgbackrest -y &>/dev/null
            else
                echoErr "valeur bolean attendu mais recu: $2"
            fi 

            ;;

        *)  
            echoErr "valeur pas pris en charge dans section special: ${1}"
            ;;
    esac

}


root_require

if [ "$1" == "change" ]; then 
    shift
    _change $@
elif [ "$1" == "read" ]; then 
    shift
    _read $@
fi