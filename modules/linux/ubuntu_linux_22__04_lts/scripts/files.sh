#!/bin/bash

source $(dirname "$0")/../lib/lib.sh


__get_file_stat() {

    # juste le chemin qui nous interresse
    path=$1

    if [ ! -f $path ]; then 
        echoErr "Fichier $path n'existe meme pas"
    fi 

    stat -c "%n %U:%G %a" $path

}


_read() {


    case "${1}" in 

        grub)
            __get_file_stat "/boot/grub/grub.cfg"
            ;;
        shadow)
            __get_file_stat "/etc/shadow"
            ;;
        group_)
            __get_file_stat "/etc/group-"
            ;;
        *)
            echoErr "Fichier pas pris en charge: $1"
            ;;


    esac



  


}

_change() {

    shift
    
    if [ $# -ne 3 ]; then
        >&2 echo "Mauvais nombre d'argument passer"
    fi 

    path=$1
    owner=$2
    perm=$3

    if [ ! -f $path ]; then 
        echoErr "Fichier $path n'existe meme pas"
    fi 

    chown $owner $path
    chmod $perm $path

}

root_require

if [ "$1" == "change" ]; then 
    shift
    _change $@

elif [ "$1" == "read" ]; then 
    shift
    _read $@
fi