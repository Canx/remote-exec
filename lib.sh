# Funciones

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pendientes_dir="${DIR}/${pendientes_dir}"
aulas_dir="${DIR}/${aulas_dir}"

function comprobar_parametros() {
  while [[ $# > 1 ]]
  do
  key="$1"

  case $key in
      -s|--script)
      script="$2"
      shift # past argument
      ;;
      -a|--aulas)
      aulas="$2"
      shift # past argument
      ;;
      -u|--usuarios)
      usuarios="$2"
      shift # past argument
      ;;
      --default)
      DEFAULT=YES
      ;;
      *)
              # unknown option
      ;;
  esac
  shift # past argument or value
  done
}

# Comprueba que exista el escript a ejecutar
function comprobar_script() {
  echo "Script a ejecutar:"${script}
  # Salimos si no existe el script a ejecutar
  if [ ! -f ${script} ]; then
    echo "Script no encontrado o no indicado."  
    # TODO: salir con mensaje de error
    exit
  else
    dir_script=$(dirname ${script})
    file_script=$(basename ${script})
  fi
}

function crear_lista_ordenadores() {
  # Si no se han indicado las aulas las procesamos todas
  if [ -z "${aulas}" ]; then
    for aula_file in ${aulas_dir}*; do
      aulas="${aulas}${aula_file} "
    done
  fi
  
  # Si hay ordenadores pendientes para el script procesamos los ordenadores pendientes
  todofile="pendientes_${file_script}"
  todofile="${todofile%.*}.txt"
  
  if [ ! -f ${pendientes_dir}${todofile} ]; then
    aulas=( ${aulas} )
  else
    aulas=( $todofile )
  fi

  # A partir de los archivos de aulas o pendientes hacemos la lista de ordenadores
  ordenadores=`cat ${aulas[@]}`
}

function comprobar_usuarios() {
 # Comprobar usuarios
  if [ ! -n "${usuarios}" ]; then
     echo "Usuarios no especificados. Utilizando usuarios por defecto: ${default_users}"
     usuarios=${default_users}
  fi
}



# ping
# $1: ordenador
function ping_ordenador() {
  command="ping -w 1 $1"
  echo $command
  eval $command &> /dev/null
  if [ $? -eq 0 ]; then
    touch "${tmp_dir}$1"
  fi
}

# Quitamos de "ordenadores" los que no hagan ping
function filtrar_ordenadores() {
  rm -rf "${tmp_dir}/*"
  for aula in "${aulas[@]}"; do
    current_size=${#ordenadores[@]}
    mapfile -O ${current_size} -t ordenadores < ${aula}
    for ordenador in ${ordenadores[@]}; do
      ping_ordenador ${ordenador} &> /dev/null &
    done
  done
}

# muestra ordenadores pendientes y los guarda
function guardar_ordenadores_pendientes() {
  if [ -n "${pendientes}" ]; then
    echo ${pendientes} > ${pendientes_dir}${todofile}
  fi
}

# TODO: falta pulir los logs!!!
# remote $1 $2
# $1: ordenador
# $2: usuario
function remote_script {
  echo "${usuario}@${ordenador} | `date +'%F %H:%M'` | ${script}" >> ${log_dir}${ordenador}
  if [ -f "${tmp_dir}$1" ]; then
    scp ${script} $2@$1:/tmp/ &> /dev/null
    if ! [ $? -eq 0 ]; then
      echo "Falta instalar sshd o usuario incorrecto." >> ${log_dir}$1
      pendientes=${pendientes}$1" "
    else
      ssh $2@$1 "source /tmp/${file_script}" > ${tmp_dir}$1 &>> ${log_dir}$1
    fi
  else
    pendientes=${pendientes}$1" "
    echo "Apagado." >> ${log_dir}$1
  fi
}

export -f remote_script
