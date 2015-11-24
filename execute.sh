#!/bin/bash
#
# execute.sh -s <script> -a <aulas> -u <usuarios>
#
source ./config.sh
source ./lib.sh

comprobar_parametros "$@"
echo "PARÁMETROS:"
echo "script:${script}"
echo "aulas:${aulas}"
echo "usuarios:${usuarios}"

comprobar_script

comprobar_usuarios
echo "USUARIOS:"${usuarios}

crear_lista_ordenadores
echo "ORDENADORES:"${ordenadores}

filtrar_ordenadores
echo "ORDENADORES_ENCENDIDOS:"${ordenadores}

crear_directorios

# Bucle principal
# TODO: añadir capacidad de procesar en paralelo o en secuencial
for usuario in "${usuarios[@]}"; do
   for ordenador in ${ordenadores[@]}; do
     echo ${usuario}@${ordenador}
     remote_script ${ordenador} ${usuario} &
   done
done
wait

guardar_ordenadores_pendientes
echo "pendientes:`cat ${pendientes_dir}${todofile}`"
