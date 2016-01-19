# Funciones

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/"
pendientes_dir="${DIR}${pendientes_dir}"
aulas_dir="${DIR}${aulas_dir}"
tmp_dir="${DIR}${tmp_dir}"
log_dir="${DIR}${log_dir}"
ssh_options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

export ordenadores=''

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
    filename_script=${file_script%.*}
  fi
}

function crear_lista_ordenadores() {

  # Si no se han indicado las aulas las procesamos todas
  if [ -z "${aulas}" ]; then
    for aula_file in ${aulas_dir}*; do
      aulas="${aulas}${aulas_dir}${aula_file} "
    done
  fi
  
  # Si hay ordenadores pendientes para el script procesamos los ordenadores pendientes
  todofile="pendientes_${file_script}"
  todofile="${todofile%.*}.txt"
  
  if [ ! -f ${pendientes_dir}${todofile} ]; then
    aulas=( ${aulas} )
  else
    aulas=( ${pendientes_dir}${todofile} )
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
  echo "Comprobando ordenadores encendidos..."
  wait
  
}

# muestra ordenadores pendientes y los guarda
function guardar_ordenadores_pendientes() {
  if [ -n "${pendientes}" ]; then
    echo ${pendientes} > ${pendientes_dir}${todofile}
  fi
}

# Loguea en un archivo los datos pasados
# $1: Mensaje
# $2: Archivo, por defecto mensajes.log en carpeta de logs
function log() {
  fecha="`date +'%F %H:%M:%S - '`"
  mensaje=$1
  archivo=$2
  echo "${fecha}:${mensaje}" >> ${log_dir}${archivo}
}

function crear_directorios() {
  echo "creando directorios..."
  mkdir -p "${log_dir}${filename_script}"
  mkdir -p "${tmp_dir}"
  mkdir -p "${pendientes_dir}"
  mkdir -p "${aulas_dir}"
}

# TODO: falta pulir los logs!!!
# remote $1 $2
# $1: ordenador
# $2: usuario
function remote_script {
  if [ -f "${tmp_dir}$1" ]; then
    scp ${ssh_options} ${script} $2@$1:/tmp/ &> /dev/null
    if ! [ $? -eq 0 ]; then
      log "${2}@${1}. Falta instalar sshd o usuario incorrecto" "errores.log"
      pendientes=${pendientes}$1" "
    else
      #touch "${DIR}${log_dir}${filename_script}/${1}"
      ssh ${ssh_options} $2@$1 "source /tmp/${file_script}" > ${tmp_dir}$1 &>> "${log_dir}${filename_script}/${1}"
    fi
  else
    pendientes=${pendientes}$1" "
    log "${2}@${1}. Apagado" "errores.log"
  fi
}

export -f remote_script
