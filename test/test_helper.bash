
# $1: ordenador
# mock que devuelve error cuando el nombre comienza por !
function ping_ordenador() {
  ordenador=$1
  if [[ ${ordenador:0:1} != "!" ]]; then touch "${tmp_dir}encendidos/$1" ; fi
}
