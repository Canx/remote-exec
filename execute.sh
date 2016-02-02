#!/bin/bash
#
# execute.sh -s <script> -a <aulas> -u <usuarios>
#
source ./config.sh
source ./lib.sh

comprobar_parametros "$@"
comprobar_script
echo "script:${script}"
echo "aulas:${aulas}"
echo "usuarios:${usuarios}"
echo

crear_lista_ordenadores
echo "lista ordenadores:"${ordenadores}

# TODO: no funciona!
filtrar_ordenadores
echo "lista ordenadores encendidos:"${encendidos[@]}

echo "PARÁMETROS:"
echo "script:${script}"
echo "aulas:${aulas}"
echo "usuarios:${usuarios}"
echo "ordenadores:${ordenadores}"


crear_directorios

# Bucle principal
# TODO: añadir capacidad de procesar en paralelo o en secuencial
for usuario in "${usuarios[@]}"; do
   for ordenador in ${encendidos[@]}; do
     echo ${usuario}@${ordenador}
     remote_script ${ordenador} ${usuario} &
   done
done
wait

guardar_ordenadores_pendientes
echo "pendientes:`cat ${pendientes_dir}${todofile}`"
