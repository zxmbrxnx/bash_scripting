#!/bin/bash

#Colores
greenColor="\e[0;32m\033[1m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
turquoiseColor="\e[0;36m\033[1m"
grayColor="\e[0;37m\033[1m"
endColor="\033[0m\e[0m"

function ctrl_c() {
    echo -e "\n\n[${redColor}!${endColor}] Saliendo...\n"
    tput cnorm && exit 1
}

## [ Ctrl + C ]
trap ctrl_c INT

## [ Variables globales ] 

# array bases de datos
databases=()

# Query a ejecutar
query=""
nameProcedure=""
parametersProcedure=""
# Logs
logs=""

# Panel de ayuda
function helpPanel() {
    echo -e "[${yellowColor}!${endColor}] Ejemplo de uso: ${grayColor}$0${endColor} ${purpleColor} -v -m -f${endColor} /ruta/script.sql"
    echo -e "[${yellowColor}!${endColor}] Ejemplo de uso: ${grayColor}$0${endColor} ${purpleColor} -qvm ${endColor}"
    echo -e "\n${grayColor}Opciones disponibles${endColor}:"
    echo -e "\t[${purpleColor}-q${endColor}] Ejecutar una query."
    echo -e "\t[${purpleColor}-f${endColor}] Ejecutar un script desde un archivo [.sql]."
    echo -e "\t[${purpleColor}-p${endColor}] Ejecutar un procedimiento almacenado."
    echo -e "\t[${purpleColor}-h${endColor}] Panel de ayuda."
        echo -e "${grayColor}Opciones adicionales${endColor}:"
    echo -e "\t[${purpleColor}-v${endColor}] Logs detallados (verbose). Se puede combinar con las demas opciones, \
ejemplo: [${purpleColor}-qv${endColor}][${purpleColor}-v -f${endColor}]"
    echo -e "\t[${purpleColor}-m${endColor}] Activar la opcion [--force] en MySQL al ejecutar la query."
    exit 1
}

function signature(){
echo -e "\n${redColor}[>_]${endColor}${grayColor} Script para ejecutar consultas SQL en MySQL${endColor}."

echo -e "   ${redColor}  ______  "
echo -e "    /\___  \ "
echo -e "    \/_/  /__ "   
echo -e "      /\_____\ X M B R X N X"
echo -e "____ _\/_____/ ________ __ ____"

echo -e "${endColor}"
}

signature
# Obtener usuario y contraseña de la base de datos
function init(){
    # Pide al usuario el usuario y la contraseña de la base de datos
    printf "\n[${greenColor}*${endColor}] Ingrese el usuario: "
    read usuario
    printf "\n[${greenColor}*${endColor}] Ingrese la contrasena: "
    read -s pass

    # Verifica si el usuario y la contraseña son correctos
    mysql -u ${usuario} -p${pass} -e "SHOW DATABASES;" > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo -e "\n\n${redColor}[x]${endColor} El usuario o la contraseña son incorrectos."
        ctrl_c
    fi

    # Crea un array para almacenar los nombres de las bases de datos
    databases=($(mysql -u ${usuario} -p${pass} -e "SHOW DATABASES;" | tr -d "| " | grep -v "Database\|information_schema\|performance_schema\|mysql"))

    # Calcular el número de elementos en el array
    num_elementos=${#databases[@]}

    # Definir el número de columnas que deseas mostrar
    num_columnas=3

    # Calcular el número de filas necesarias para imprimir todos los elementos
    num_filas=$((num_elementos / num_columnas))
    echo -e "\n\n"
    printf "+-----------------------------------------------------------------------------------------------+\n"
    echo -e "|                                      BASES DE DATOS                                           |"
    printf "+-----------------------------------------------------------------------------------------------+\n\n"

    # Imprimir el array en forma de columnas
    for ((i = 0; i < num_filas; i++)); do
        printf "[${greenColor}%d${endColor}] %-30s [${greenColor}%d${endColor}] %-30s [${greenColor}%d${endColor}] %-30s${endColor}\n" \
                "${i}" "${databases[i]}" "$((i + num_filas))" "${databases[i + num_filas]}" "$((i + (num_filas * 2)))" "${databases[i + (num_filas * 2)]}"
    done

    # Si hay elementos sobrantes que no caben en las columnas, imprimirlos en una última fila
    restantes=$((num_elementos % num_columnas))
    if [ $restantes -gt 0 ]; then
        for ((i = num_elementos - restantes; i < num_elementos; i++)); do
            printf "[${greenColor}%d${endColor}] %-30s" "${i}" "${databases[i]}"
        done
        echo # Imprimir una nueva línea después de la última fila incompleta
    fi

    while true; do
        # Pide al usuario el índice del elemento a eliminar
        printf "\n[${greenColor}+${endColor}] Ingrese los indices a eliminar (separados por espacios) o escriba [continuar]: "
        read -r indices_a_eliminar

        # Verifica si el usuario ha decidido continuar
        if [[ $indices_a_eliminar == "continuar" ]]; then
            break
        fi

        # Convertir la entrada en una lista de índices
        IFS=" " read -r -a indices_array <<< "$indices_a_eliminar"

        # Validar que los índices ingresados sean válidos
        for index in "${indices_array[@]}"; do
            if [ "$index" -lt 0 ] || [ "$index" -ge "${#databases[@]}" ]; then
                echo -e "\n[${redColor}x${endColor}] Indice invalido: $index"
            fi
        done

        # Eliminar los elementos del array
        eliminar_elementos "${indices_array[@]}"

        # Imprime el array actualizado
        echo -e "\n"
        printf "+-----------------------------------------------------------------------------------------------+\n"
        echo -e "|                                BASES DE DATOS ACTUALIZADAS                                    |"
        printf "+-----------------------------------------------------------------------------------------------+\n\n"

        # Calcular el número de elementos en el array
        num_elementos=${#databases[@]}

        # Definir el número de columnas que deseas mostrar
        num_columnas=3

        # Calcular el número de filas necesarias para imprimir todos los elementos
        num_filas=$((num_elementos / num_columnas))

        # Imprimir el array en forma de columnas
        for ((i = 0; i < num_filas; i++)); do
            printf "[${greenColor}%d${endColor}] %-30s [${greenColor}%d${endColor}] %-30s [${greenColor}%d${endColor}] %-30s${endColor}\n" \
                    "${i}" "${databases[i]}" "$((i + num_filas))" "${databases[i + num_filas]}" "$((i + (num_filas * 2)))" "${databases[i + (num_filas * 2)]}"
        done

        # Si hay elementos sobrantes que no caben en las columnas, imprimirlos en una última fila
        restantes=$((num_elementos % num_columnas))
        if [ $restantes -gt 0 ]; then
            for ((i = num_elementos - restantes; i < num_elementos; i++)); do
                printf "[${greenColor}%d${endColor}] %-30s" "${i}" "${databases[i]}"
            done
            echo # Imprimir una nueva línea después de la última fila incompleta
        fi

    done
}

# Función para eliminar elementos de un array
function eliminar_elementos() {
    local indices_a_eliminar=("$@")
    local nuevo_array=()
    # Recorrer el array original y copiar los elementos que no estén en el array de índices a eliminar
    for i in $(seq 0 $((${#databases[@]} - 1))); do
        # Si el índice actual no está en el array de índices a eliminar, copiar el elemento
        if ! echo "${indices_a_eliminar[@]}" | grep -q "\b$i\b"; then
            nuevo_array+=("${databases[i]}")
        fi
    done
    # Actualizar el array original
    databases=("${nuevo_array[@]}")
}

function getQuery(){
    # Types: 1 = query, 2 = procedure, 3 = view
    local type=$1

    if [[ $type == 1 ]]; then
        echo -e "\n[${yellowColor}!${endColor}] Escriba la query a ejecutar y pulse [ENTER], al terminar pulse [Ctrl+D]: \n"

        while read -r linea; do
            #agrega cada linea a la query
            query="$query \n$linea"
        done

        #Se valida si la query no termina en ; o si no termina en espacio y se agrega ;
        if [[ $query != *";" ]]; then
            query="$query;"
        fi

    elif [[ $type == 2 ]]; then
        printf "\n[${greenColor}+${endColor}] Ingrese el nombre del procedimiento: "
        read nameProcedure

        printf "\n[${greenColor}+${endColor}] Parametros del procedimiento (separados por espacios): "
        read parametersProcedure

        echo -e "\n[${yellowColor}!${endColor}] Cuerpo del procedimiento a crear, al terminar pulse [Ctrl+D]: \n"
        
        while read -r linea; do
            #agrega cada linea a la query
            query="$query \n$linea"
        done
    elif [[ $type == 3 ]]; then
        echo -e "\n[${yellowColor}!${endColor}] Escriba el nombre de la vista a crear y pulse [ENTER], al terminar pulse [Ctrl+D]: \n"
    fi

    #Se valida si la query es vacia
    if [[ $query == ";" ]]; then
        echo -e "\n[${redColor}x${endColor}] La query no puede estar vacia.\n"
        getQuery
    fi

}

function confirmation(){
    local msg=$1
    #Confirmacion de la ejecucion del script.
    printf "\n[${purpleColor}!${endColor}] Esta seguro que desea ejecutar $msg en todas las bases de datos selecionadas?[si/no]: "
    
    while true; do
        read confirmacion

        #Salir del ciclo y continuar
        if  [[ $confirmacion == "si" ]]; then
            break
        fi
    
        #Salir del script si elige no
        if [[ $confirmacion == "no" ]]; then
            ctrl_c
        else
            printf "\n[${redColor}x${endColor}] La respuesta es incorrecta, por favor escriba [si] para continuar o [no] para salir: "
        fi
    
    done
}

function runQuery(){
    init
    getQuery 1
 
    echo -e "\n[${greenColor}+${endColor}] La query a ejecutar es: \n"
    echo -e "$query"

    confirmation "la query"

    echo -e "\n[${greenColor}!${endColor}] Ejecutando la query en todas las bases de datos selecionadas...\n\n"

    #Se ejecuta la query en todas las bases de datos que se dejaron en el array
    log="Log fecha: $(date +"%Y-%m-%d %H:%M:%S") \n"
    log="$log \nQuery: \n$query \n"
    log="$log \nLOGS: \n"

    tput civis
    for db in "${databases[@]}"; do
        echo -n "[${db}]: "
        log="$log \n[${db}]:" 

        echo -e "$query" > .query_tmp.sql

        if [ $force_mysql -eq 1 ]; then
            salida=$(mysql -u ${usuario} -p${pass} -f ${db} < .query_tmp.sql 2>&1)
        else
            salida=$(mysql -u ${usuario} -p${pass} ${db} < .query_tmp.sql 2>&1)
        fi

        if [ $? -eq 0 ]; then
            salida=$(echo "$salida" | sed 's/PAGER set to stdout//g')
            if [ $verbose -eq 1 ]; then
                log="$log OK. \n-Resultados- \n$salida \n"
                echo -e "OK. \n-Resultados- \n$salida"
            else
                log="$log OK."
                echo "OK."
            fi
        else
            salida=$(echo "$salida" | sed 's/PAGER set to stdout//g')
            if [ $verbose -eq 1 ]; then
                log="$log Error. \n-Resultados-\n$salida \n"
                echo -e "Error. \n-Resultados-\n$salida"
            else
                log="$log $salida"
                echo "Error."
            fi
        fi
    done
    tput cnorm
    
    # Guardar el log en el directorio actual
    echo -e "$log" > sql_query_$(date +"%Y%m%d%H%M%S").log


}

function runQueryFile(){
    file=$1

    #Se valida si el archivo existe
    if [ ! -f "$file" ]; then
        echo -e "\n[${redColor}x${endColor}] El archivo [$file] no existe."
        ctrl_c
    fi

    #Se valida si el archivo esta vacio
    if [ ! -s "$file" ]; then
        echo -e "\n[${redColor}x${endColor}] El archivo [$file] esta vacio."
        ctrl_c
    fi

    #Se valida si el archivo es un archivo de texto
    if ! file "$file" | grep -q "text"; then
        echo -e "\n[${redColor}x${endColor}] El archivo [$file] no es un archivo de texto."
        ctrl_c
    fi

    init

    echo -e "\n[${greenColor}+${endColor}] El archivo a ejecutar es: \n"
    cat $file
    echo -e "\n"
    #Confirmacion de la ejecucion del script.
    confirmation "el archivo [$file]"

    echo -e "\n[${greenColor}!${endColor}] Ejecutando el archivo en todas las bases de datos selecionadas...\n\n"

    #Se ejecuta la query en todas las bases de datos que se dejaron en el array
    log="Log fecha: $(date +"%Y-%m-%d %H:%M:%S") \n"
    log="$log \nQuery: \n$(cat $file) \n"
    #log="$log \nQuery: \n$(cat $file) \n"
    log="$log \nLOGS: \n"
    tput civis
    for db in "${databases[@]}"; do
        echo -n -e "\n[${db}]: "
        log="$log \n[${db}]:"

        if [ $force_mysql -eq 1 ]; then
            salida=$(mysql -u ${usuario} -p${pass} -f ${db} < ${file} 2>&1)
        else
            salida=$(mysql -u ${usuario} -p${pass} ${db} < ${file} 2>&1)
        fi

        if [ $? -eq 0 ]; then
            salida=$(echo "$salida" | sed 's/PAGER set to stdout//g')
            if [ $verbose -eq 1 ]; then
                log="$log OK. \n-Resultados- \n$salida \n"
                echo -e "OK. \n-Resultados- \n$salida"
            else
                log="$log OK."
                echo "OK."
            fi
        else
            salida=$(echo "$salida" | sed 's/PAGER set to stdout//g')
            if [ $verbose -eq 1 ]; then
                log="$log Error. \n-Resultados-\n$salida \n"
                echo -e "Error. \n-Resultados-\n$salida"
            else
                log="$log $salida"
                echo "Error."
            fi
        fi
    done
    tput cnorm
    # Guardar el log en el directorio actual
    echo -e "$log" > sql_file_$(date +"%Y%m%d%H%M%S").log

}

function runProcedure(){
    init
    getQuery 2

    echo -e "\n[${greenColor}+${endColor}] La query a ejecutar es: \n"

    # Nombre del procedimiento
    local queryProcedure="DELIMITER // \n"
    queryProcedure="${queryProcedure}CREATE DEFINER='DEFINER'@'%' PROCEDURE IF NOT EXISTS ${nameProcedure}(${parametersProcedure})"
    # Cuerpo del procedimiento
    queryProcedure="${queryProcedure}\nBEGIN"
    queryProcedure="${queryProcedure} ${query}"
    queryProcedure="${queryProcedure}\nEND//"
    queryProcedure="${queryProcedure}\nDELIMITER ;"
    echo -e "$queryProcedure"

    confirmation "el procedimiento"

    echo -e "\n[${greenColor}!${endColor}] Ejecutando el procedimiento en todas las bases de datos selecionadas...\n\n"

    #Se ejecuta la query en todas las bases de datos que se dejaron en el array
    log="Log fecha: $(date +"%Y-%m-%d %H:%M:%S") \n"
    log="$log \nQuery: \n\n$queryProcedure \n"
    log="$log \nLOGS: \n"

    tput civis
    for db in "${databases[@]}"; do
        #echo -n "[${db}]: "
        log="$log \n[${db}]:"

        queryProcedure="DELIMITER // \n"
        queryProcedure="${queryProcedure}CREATE DEFINER='${db}'@'%' PROCEDURE IF NOT EXISTS ${nameProcedure}(${parametersProcedure})"
        # Cuerpo del procedimiento
        queryProcedure="${queryProcedure}\nBEGIN"
        queryProcedure="${queryProcedure} ${query}"
        queryProcedure="${queryProcedure}\nEND//"
        queryProcedure="${queryProcedure}\nDELIMITER ;"

        echo -e "$queryProcedure" > .procedure_tmp.sql

        salida=$(mysql -u ${usuario} -p${pass} ${db} < .procedure_tmp.sql 2>&1)

        if [ $? -eq 0 ]; then
            salida=$(echo "$salida" | sed 's/PAGER set to stdout//g')
            if [ $verbose -eq 1 ]; then
                log="$log OK. \n-Resultados- \n$salida \n"
                echo -e "OK. \n-Resultados- \n$salida"
            else
                log="$log OK."
                echo "OK."
            fi
        else
            salida=$(echo "$salida" | sed 's/PAGER set to stdout//g')
            if [ $verbose -eq 1 ]; then
                log="$log Error. \n-Resultados-\n$salida \n"
                echo -e "Error. \n-Resultados-\n$salida"
            else
                log="$log $salida"
                echo "Error."
            fi
        fi
    done
    tput cnorm

    # Guardar el log en el directorio actual
    echo -e "$log" > sql_procedure_$(date +"%Y%m%d%H%M%S").log    
}

# Indicadores
declare -i parameter_counter=0
declare -i verbose=0
declare -i force_mysql=0

while getopts "qpf:hvm" arg; do
    case $arg in
        q) 
            let parameter_counter+=1
            if [ $parameter_counter -eq 3 ]; then
                echo -e "\n[${redColor}!${endColor}] No se puede ejecutar una query y un archivo a la vez."
                ctrl_c
            fi
            ;;
        f) 
            filePath=$OPTARG; 
            let parameter_counter+=2
            if [ $parameter_counter -eq 3 ]; then
                echo -e "\n[${redColor}!${endColor}] No se puede ejecutar una query y un archivo a la vez."
                ctrl_c
            fi           
            ;;
        p) 
            let parameter_counter+=3
            
            if [ $parameter_counter -eq 4 ]; then
                echo -e "\n[${redColor}!${endColor}] No se puede ejecutar una query y un prodecimiento a la vez."
                ctrl_c
            fi
            if [ $parameter_counter -eq 3 ]; then
                echo -e "\n[${redColor}!${endColor}] No se puede ejecutar un archivo y un procedimiento a la vez."
                ctrl_c
            fi
            ;;
        v) let verbose=1;;
        m) let force_mysql=1;;
        h) ;;
    esac
done

if [ $parameter_counter -eq 1 ]; then
    runQuery
elif [ $parameter_counter -eq 2 ]; then
    runQueryFile $filePath
elif [ $parameter_counter -eq 3 ]; then
    runProcedure
else
    helpPanel
fi