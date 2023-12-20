#!/bin/bash

source $(dirname "$0")/../lib/lib.sh


CONF_FILE="/etc/security/pwquality.conf"

_read() {

    case "${1}" in

        minlen) 
            # juste les ligne qui ne sont pas commenter
            minlen=$(grep -P "^[\s]*minlen[\s]*=[\s]*[0-9]*" $CONF_FILE | awk -F= '{ gsub(/ /,""); print $2 }')    

            # valeur par defaut si on ne trouve pas
            if [ -z "$minlen" ]; then 
                echo "8"
            else
                echo $minlen
            fi

            ;;

        minclass)

            minclass=$(grep -P "^[\s]*minclass[\s]*=[\s]*[0-9]*" $CONF_FILE | awk -F= '{ gsub(/ /,""); print $2 }')

            # valeur par defaut si on ne trouve pas
            if [ -z "$minclass" ]; then 
                echo "0"
            else
                echo $minclass
            fi
            

            ;;

        dcredit)

            dcredit=$(grep -P "^[\s]*dcredit[\s]*=[\s]*[0-9]*" $CONF_FILE | awk -F= '{ gsub(/ /,""); print $2 }')
            # valeur par defaut si on ne trouve pas
            if [ -z "$dcredit" ]; then 
                echo "0"
            else 
                echo $dcredit
            fi

            ;;

        ucredit)

            ucredit=$(grep -P "^[\s]*ucredit[\s]*=[\s]*[0-9]*" $CONF_FILE | awk -F= '{ gsub(/ /,""); print $2 }')
            # valeur par defaut si on ne trouve pas
            if [ -z "$ucredit" ]; then 
                echo "0"
            else
                echo $ucredit
            fi

            ;;

        ocredit)

            ocredit=$(grep -P "^[\s]*ocredit[\s]*=[\s]*[0-9]*" $CONF_FILE | awk -F= '{ gsub(/ /,""); print $2 }')

            # valeur par defaut si on ne trouve pas
            if [ -z "$ocredit" ]; then 
                echo "0"
            else
                echo $ocredit
            fi

            ;;

        lcredit)

            lcredit=$(grep -P "^[\s]*lcredit[\s]*=[\s]*[0-9]*" $CONF_FILE | awk -F= '{ gsub(/ /,""); print $2 }')

            # valeur par defaut si on ne trouve pas
            if [ -z "$lcredit" ]; then 
                echo "0"
            else
                echo $lcredit
            fi

            ;;

        *)  
            echoErr "Argument $1 pas pris en charge"
            ;;

    esac



}


_change() {

    if [ $# -ne 2 ]; then 
        echoErr "Invalide nombre d'argument"
    fi 

    case "${1}" in

        minlen) 

            sed -i "s/.*minlen.*/minlen = $2/" $CONF_FILE
            ;;

        minclass)

            sed -i "s/.*minclass.*/minclass = $2/" $CONF_FILE
            ;;

        dcredit)

            sed -i "s/.*dcredit.*/dcredit = $2/" $CONF_FILE
            ;;

        ucredit)
            sed -i "s/.*ucredit.*/ucredit = $2/" $CONF_FILE
            ;;

        ocredit)
            sed -i "s/.*ocredit.*/ocredit = $2/" $CONF_FILE
            ;;

        lcredit)
            sed -i "s/.*lcredit.*/lcredit = $2/" $CONF_FILE
            ;;
        
        *)
            echoErr "Parametre pas pris en charge: $1"

    esac

}


root_require

if [ ! -f $CONF_FILE ]; then
    echoErr "pwquality ne semble ne pas etre installer sur votre machine"
fi 

if [ "$1" == "change" ]; then 
    shift
    _change $@
elif [ "$1" == "read" ]; then 
    shift
    _read $@
fi