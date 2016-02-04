#!/usr/bin/env bats

source "config.sh" > /dev/null 2>/dev/null
source "lib.sh" > /dev/null 2>/dev/null

load test_helper # incluye mockup que no hace ping a los ordenadores que comienzan por !

@test "Enumera correctamente el número de ordenadores" {
   ordenadores=( '!ordenador1' '!ordenador2' 'ordenador3' )
   encendidos=()

   # Debe quitar los ordenadores que no hacen ping 
   filtrar_ordenadores
   num_encendidos=${#encendidos[@]}
   echo ${ordenadores[@]}
   [ "$num_encendidos" -eq 1 ]

} 

@test "Cuando no hay ordenadores encendidos debe ser vacío" {
   ordenadores=()
   encendidos=()

   filtrar_ordenadores
   num_encendidos=${#encendidos[@]}
   echo ${ordenadores[@]}
   [ "$num_encendidos" -eq 0 ]
}

@test "Despues de filtrar no deben haber archivos en tmp/" {
   ordenadores=(ordenador1 ordenador2 ordenador3)
   encendidos=()

   filtrar_ordenadores
   [ $(ls -1 ${tmp_dir} | wc -l) -eq 0 ]
}
