#!/bin/bash

source $(dirname "$0")/../lib/lib.sh


_read() {


    case "${1}" in

        daemons)

            chrony=""
            ntp=""
            system_tsync=""
            
            daemons=()

            dpkg-query -W chrony > /dev/null 2>&1 && daemons+=("'chrony'")
            dpkg-query -W ntp > /dev/null 2>&1 && daemons+=("'ntp'")

            timesync=$(systemctl is-enabled systemd-timesyncd.service)

            if [ "$timesync" == "enabled" ]; then
                daemons+=("'systemd-timesyncd'")
            fi 
            
            echo ${daemons[@]}


            ;;

        *)
            echoErr "Argument pas pris en charge dans section 'timesync': $1"
            ;;



    esac 


}


_change() {

    case "${1}" in

        daemons)

            shift

            if [[ $@ =~ "systemd-timesyncd" ]]; then
                echo "bruhhhh"
                systemctl enable --now systemd-timesyncd
            else
                systemctl stop systemd-timesyncd.service
                systemctl disable systemd-timesyncd.service
            fi 

            if [[ $@ =~ "chrony" ]]; then 
                apt install chrony -y &>/dev/null
            else 
                apt remove chrony -y && apt autoremove &>/dev/null
                apt purge chrony -y &>/dev/null
            fi 

            if [[ $@ =~ "ntp" ]]; then
                apt install ntp -y && apt autoremove &>/dev/null
            else
                apt remove ntp -y && apt autoremove -y &>/dev/null 
                apt purge ntp -y &>/dev/null
            fi 
        
            ;;

        *)
            echoErr "Argument pas pris en charge dans section 'timesync': $1"
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