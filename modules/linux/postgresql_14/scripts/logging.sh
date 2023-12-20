#!/bin/bash

source $(dirname "$0")/../lib/lib.sh

_read() {

    case "${1}" in
        log-destination)
            dtype=$( runuser \
                -l postgres \
                -c "psql  -c '\x' -c 'SHOW log_destination' -q" | \
                grep log_destination | \
                tr -d '[:space:]' | \
                awk '{split($0,sline,"|"); print sline[2]}'
            )

            sdata=$(split_array ',' $dtype)

            output=()

            for name in $(split_array ',' $dtype); do 
                output+=("'$name'")
            done 
            

	    echo "${output[@]}"
            ;;

        log-trunc-on-rotation)
            status=$( runuser \
                -l postgres \
                -c "psql  -c '\x' -c 'SHOW log_truncate_on_rotation' -q" | \
                grep log_truncate_on_rotation | \
                tr -d '[:space:]' | \
                awk '{split($0,sline,"|"); print sline[2]}'
            )

            if [ "$status" == "on" ]; then
                echo "1"
            elif [ "$status" == "off" ]; then
                echo "0"
            fi 

            ;;

        pgaudit)
            
            runuser -l postgres  -c "psql  -c '\x' -c 'SHOW shared_preload_libraries' -q" | grep pgaudit &>/dev/null

            if [ $? -eq 0 ]; then
                echo "1"
            else
                echo "0"
            fi 
            ;;
        debug-print-plan)

            status=$( runuser \
                -l postgres \
                -c "psql  -c '\x' -c 'SHOW debug_print_plan' -q" | \
                grep debug_print_plan | \
                tr -d '[:space:]' | \
                awk '{split($0,sline,"|"); print sline[2]}'
            )

            if [ "$status" == "on" ]; then 
                echo "1"
            elif [ "$status" == "off" ]; then 
                echo "0"
            else
                echoErr "valeur innatendu: '$status'"
            fi 

            ;;

        *)  
            echoErr "valeur pas pris en charge dans section logging: ${1}"
            ;;
    esac 

}


_change() {

    case "${1}" in
        log-destination)
            shift
            arg=$(join_array ',' $@ )

            runuser -l postgres  -c "psql  -q -c '\x' -c 'ALTER SYSTEM set log_destination =  \"$arg\"'" 

            systemctl reload postgresql
            ;;

        log-trunc-on-rotation)

            arg=""
            if [ "$2" == "1" ]; then 
                arg="on"
            elif [ "$2" == "0" ]; then
                arg="off"
            else
                echoErr "valeur boolean attendu mais recu: $2"
            fi 

            runuser -l postgres  -c "psql  -q -c '\x' -c 'ALTER SYSTEM set log_truncate_on_rotation =  \"$arg\"'" 

            systemctl reload postgresql
            ;;

        pgaudit)

            if [ "$2" == "1" ]; then
                apt install postgresql-14-pgaudit -y &>/dev/null
                grep -P "^[\s]*shared_preload_libraries[\s]*" $(get_postgresql_conf_path) &>/dev/null

                if [ $? -eq 0 ]; then

                    lib=$( runuser \
                        -l postgres \
                        -c "psql -c '\x' -c 'SHOW shared_preload_libraries' -q" | \
                        grep log_truncate_on_rotation | \
                        tr -d '[:space:]' | \
                        awk '{split($0,sline,"|"); print sline[2]}'
                    )

                    lib=$(split_array ',' $lib)
                    arg=""

                    if [ -z $lib ]; then 
                        arg="pgaudit"
                    else 
                        if [[ ! "${lib[@]}" =~ "pgaudit" ]]; then
                            lib+=("pgaudit")                    
                        fi
                   
                        arg=$(join_array ',' "$lib")
                    
                    fi 
     
                    sed -i "s/^[[:blank:]]*shared_preload_libraries.*/shared_preload_libraries = '$arg'/" $(get_postgresql_conf_path)
                
                
                elif [ $? -eq 1 ]; then 
                    echo "shared_preload_libraries = 'pgaudit'" >> $(get_postgresql_conf_path)
                
                else 
                    echoErr "Erreur inatendu est survenu: exit code grep: $?"
                fi 

            elif [ "$2" == "0" ]; then

                apt purge postgresql-14-pgaudit -y &>/dev/null
                apt remove -y postgresql-14-pgaudit &>/dev/null

                grep -P "^[\s]*shared_preload_libraries[\s]*" $(get_postgresql_conf_path) &>/dev/null

                if [ $? -eq 0 ]; then 
                    # capture tous les librairie
                    libs=$( runuser \
                        -l postgres \
                        -c "psql -c '\x' -c 'SHOW shared_preload_libraries' -q" | \
                        grep log_truncate_on_rotation | \
                        tr -d '[:space:]' | \
                        awk '{split($0,sline,"|"); print sline[2]}'
                    )

                    # transforme en une array
                    args=()
                    # enleve pgaudit de la liste

                    for elem in $(split_array ',' "$libs"); do 
                        if [[ "$elem" != "pgaudit" ]]; then
                            args+=($elem)
                        fi
                    done 
    
                    # modifie la config sans pgaudit
                    sed -i "s/^[[:blank:]]*shared_preload_libraries.*/shared_preload_libraries = '$args'/" $(get_postgresql_conf_path)

                fi 

            else 
                echoErr "valeur boolean attendu mais recu: $2"
            fi 

            systemctl restart postgresql

            ;;
        debug-print-plan)

            arg=""
            if [ "$2" == "1" ]; then 
                arg="on"
            elif [ "$2" == "0" ]; then
                arg="off"
            else
                echoErr "valeur boolean attendu mais recu: $2"
            fi 

            runuser -l postgres  -c "psql  -q -c '\x' -c 'ALTER SYSTEM set debug_print_plan =  \"$arg\"'" 

            systemctl reload postgresql

            ;;

        *)  
            echoErr "valeur pas pris en charge dans section logging: ${1}"
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



sed -i "s/^[[:blank:]]*shared_preload_libraries.*/shared_preload_libraries = ''/" $(get_postgresql_conf_path)
