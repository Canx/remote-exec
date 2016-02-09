# Funciones

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/"
pendientes_dir="${DIR}${pendientes_dir}"
tmp_dir="${DIR}${tmp_dir}"
log_dir="${DIR}${log_dir}"
ssh_options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
bold=$(tput bold)
normal=$(tput sgr0)

aulas=()
ordenadores=()
encendidos=()
export aulas ordenadores encendidos

# $1: mensaje de error
function error() {
    echo "${bold}ERROR: $1${normal}"
    echo
    echo "Modo de empleo: $ execute.sh -s [script] -a [aulas] -u [usuarios]"
    echo
    echo "Ejecuta el script en las aulas y para los usuarios indicados."
    echo "  [script] debe ser la ruta y nombre completo de un shell script."
    echo "  [aulas] debe ser uno a más nombres de archivos separados por espacios, que contenga cada uno una IP o nombre de dispositivo por linea."
    echo "  [usuarios] debe ser uno o más nombres de usuarios separados por espacios que esten en todos los dispositivos indicados."
    echo
    echo "Ejemplos:"
    echo "  execute.sh -s scripts/ps.sh -a aula1 -u admin"
    echo "  execute.sh -s scripts/ps.sh -a aula1 aula2 -u user1 user2"
    echo
    exit 1
}

export ordenadores=''

function comprobar_parametros() {
  while [[ $# > 1 ]]
  do
  key="$1"

  case $key in
      -s|--script)
      param_script="$2"
      shift # past argument
      ;;
      -a|--aulas)
      param_aulas="$2"
      shift # past argument
      ;;
      -u|--usuarios)
      param_usuarios="$2"
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
 
  # Si algún parámetro no está damos mensaje de error y salimos
  if [ -z "${param_script}" ] || [ -z "${param_usuarios}" ] || [ -z "${param_aulas}" ]; then
    error "debe indicar el script, aula y usuario" 
  fi

  comprobar_script
  comprobar_usuarios
  comprobar_aulas
}
 
# Comprueba que exista el script a ejecutar
function comprobar_script() {
  # Salimos si no existe el script a ejecutar
  if [ ! -f ${param_script} ]; then
    error "script '${param_script}' no encontrado o no indicado."  
  else
    script=${param_script}
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
}

function comprobar_usuarios() {
  # TODO: comprobar que sea una lista válida (no tenga caracteres raros)
  usuarios=( $param_usuarios )
}

function comprobar_aulas() {
  for aula_file in ${param_aulas}; do
      # TODO: comprobar que existen los ficheros antes de añadirlos
      if [ ! -f ${aula_file} ]; then
         error "No existe el archivo de aulas ${aula_file}"
      fi
      aulas="${aula_file} "
  done
}

# TODO: por rehacer
#function comprobar_ordenadores_pendientes() {
#  todofile="pendientes_${file_script}"
#  todofile="${todofile%.*}.txt"
#  
#  if [ ! -f ${pendientes_dir}${todofile} ]; then
#    aulas=( ${aulas} )
#  else
#    aulas=( ${pendientes_dir}${todofile} )
#  fi
#}

function crear_lista_ordenadores() {
  # cambio el archivo de aulas si hay ordenadores pendientes
  comprobar_ordenadores_pendientes
  # A partir de los archivos de aulas o pendientes hacemos la lista de ordenadores
  ordenadores=`cat ${aulas[@]}`
}

# ping
# $1: ordenador
function ping_ordenador() {
  echo "ping_ordenador()"
  command="ping -w 2 $1"
  echo $command
  eval $command
  if [ $? -eq 0 ]; then
    touch "${tmp_dir}encendidos/$1"
  fi
}

# Que pasa si ejecutamos un comando otra vez?
# Debe continuar desde lo realizado si detecta un archivo pending en el comando!!!
function check_pending() {


}

# Leemos el fichero ${log_dir}/${comando}/pending
# y creamos el array ${pendientes} a partir de él
function load_pending() {
  if [ -f "${log_dir}/${comando}/pending" ]; then
    readarray pendientes < ${log_dir}/${comando}/pending
  fi 
}

# Quitamos de "ordenadores" los que ya esten procesados y los que no esten alcanzables por ping
function filtrar_ordenadores() {
  # TODO: quitar ordenadores ya procesados en otra ocasión
  
  load_pending

  # comprobar_ordenadores_encendidos
 
  rm -rf "${tmp_dir}*"
  [ -d "${tmp_dir}encendidos" ] || mkdir -p "${tmp_dir}encendidos"
  for ordenador in ${ordenadores[@]}; do
    ping_ordenador ${ordenador} &> /dev/null &
  done
  echo "Comprobando ordenadores encendidos..."
  wait

  # creamos array de encendidos y apagados
  for ordenador in ${ordenadores[@]}; do
     if test -f ${tmp_dir}encendidos/${ordenador}; then
       encendidos+=( ${ordenador} )
     else
       apagados+=( ${ordenador} )
     fi
  done

  # Limpiamos
  rm -rf "${tmp_dir}"
}


# muestra ordenadores pendientes y los guarda
function guardar_ordenadores_pendientes() {
  if [ -n "${pendientes}" ]; then
    echo ${pendientes} >> ${pendientes_dir}${todofile}
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
}

# $1: ordenador
# $2: causa del estado pendiente (1 palabra)
# $3: causa del estado pendiente (descripción larga)
function add_pending() {
  # 
  # Añadimos el ordenador a un fichero del tipo
  #
  echo "$1" >> ${pendientes_dir}
  log "${1}: ${3}" "errores.log"
}

# TODO: falta pulir los logs!!!
# remote $1 $2
# $1: ordenador
# $2: usuario
function remote_script() {
  if [ -f "${tmp_dir}encendidos/$1" ]; then
    scp ${ssh_options} ${script} $2@$1:/tmp/ &> /dev/null
    if ! [ $? -eq 0 ]; then
      log "${2}@${1}. Falta instalar sshd o usuario incorrecto" "errores.log"
      # TODO: debemos crear archivos, no valen variables (multithreaded)!!!!
      add_pending($1, "ssh", "Error ssh")
    else
      #touch "${DIR}${log_dir}${filename_script}/${1}"
      ssh ${ssh_options} $2@$1 "source /tmp/${file_script}" > ${tmp_dir}$1 &>> "${log_dir}${filename_script}/${1}"
    fi
  else
    add_pending($1, "off", "Apagado")
  fi
}

#export -f remote_script
