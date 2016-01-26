
# $1: ordenador
# mock que devuelve error cuando el nombre comienza por !
function ping_ordenador() {
  if [[ ${str:0:1} == "!" ]] ; then echo 1; else echo 0; fi
}
