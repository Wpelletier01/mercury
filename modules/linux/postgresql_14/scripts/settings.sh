#!/bin/bash

source $(dirname "$0")/../lib/lib.sh


_read() {


    case "${1}" in

        enable-tls) 
            resp=$(runuser -l postgres -c "psql -c '\x' -c 'SHOW ssl' -q" | grep "ssl" | tr -d '[:space:]' | awk '{split($0,sline,"|"); print sline[2]}')
            
            if [ "$resp" == "on" ]; then
                echo "1"
            elif [ "$resp" == "off" ]; then
                echo "0"
            else 
                echoErr "Incapable d'aller chercher la valeur enable-tls: retourne $resp"
            fi 
            ;;


        *)

            echoErr "valeur pas pris en charge dans section settings: ${1}"
            ;;
    esac 

}


_change() {

    case ${1} in 

        enable-tls)            
            if [ "$2" == "1" ]; then
                sed -i "s/^[[:blank:]]*ssl[[:blank:]]*[^_].*[on|off]/ssl = on/" $(get_postgresql_conf_path)
                
            elif [ "$2" == "0" ]; then 
                sed -i "s/^[[:blank:]]*ssl[[:blank:]]*[^_].*[on|off]/ssl = off/" $(get_postgresql_conf_path)
            else 
                echoErr "Valeur boolean attendu mais recu: $2"
            fi 
            
            ;;
        *)
            echoErr "valeur pas pris en charge dans section settings: ${1}"
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