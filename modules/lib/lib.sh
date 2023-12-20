#!/bin/bash

echoErr() {   
    >&2 echo $@
    exit 1
}

root_require() {
    if [ "$EUID" -ne 0 ]; then 
        echoErr "Vous n'avez pas les droit necessaire pour executer le script"
    fi
}

join_array() {

    local IFS="$1"
    shift
    echo "$*"

}

split_array() {

    local IFS="$1"
    read -r -a array <<< "$2"
    echo ${array[@]}
}

get_postgresql_conf_path() {

    path=$(runuser \
        -l postgres \
        -c "psql -c '\x' -c 'SHOW config_file' -q" | \
        grep config_file | \
        tr -d '[:space:]' | \
        awk '{split($0,sline,"|"); print sline[2]}'
    )

    echo "$path"
}