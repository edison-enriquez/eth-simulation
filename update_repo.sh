#!/bin/bash

# Función para mostrar el uso del script
function show_usage() {
  echo "Uso: $0 [-b nombre_de_la_rama] [-c 'mensaje del commit']"
  exit 1
}

# Valores por defecto
branch_name="main"
commit_message=""

# Parsear los argumentos
while getopts ":b:c:" opt; do
  case $opt in
    b)
      branch_name=$OPTARG
      ;;
    c)
      commit_message=$OPTARG
      ;;
    \?)
      echo "Opción inválida: -$OPTARG" >&2
      show_usage
      ;;
    :)
      echo "La opción -$OPTARG requiere un argumento." >&2
      show_usage
      ;;
  esac
done
shift $((OPTIND -1))

# Verifica si se proporcionó un mensaje de commit
if [ -z "$commit_message" ]; then
  show_usage
fi

# Inicializa Git LFS si no se ha hecho antes
git lfs install

# Navega al directorio del repositorio (opcional)
# cd /ruta/al/repositorio

# Agrega todos los cambios al área de staging
git add -A

# Crea un commit con el mensaje proporcionado
git commit -m "$commit_message"

# Extrae los cambios más recientes del repositorio remoto
git pull origin "$branch_name"

# Verifica si hubo conflictos durante el pull
if [ $? -ne 0 ]; then
  echo "Hubo conflictos durante el pull. Resuélvelos y luego ejecuta 'git push'."
  exit 1
fi

# Empuja los cambios al repositorio remoto
git push origin "$branch_name"

# Verifica si el push fue exitoso
if [ $? -ne 0 ]; then
  echo "Hubo un error al hacer push. Verifica los mensajes de error anteriores."
  exit 1
fi

echo "Repositorio actualizado exitosamente en la rama '$branch_name'."
