#!/bin/bash

# Función para mostrar el uso del script
function show_usage() {
  echo "Uso: $0 [-b nombre_de_la_rama] [-c 'mensaje del commit']"
  exit 1
}

# Valores por defecto
branch_name="main"
commit_message="Actualizando carpeta eth_forge"

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

# Inicializa Git LFS si no se ha hecho antes
git lfs install

# Agregar la carpeta eth_forge al área de staging
git add eth_forge/

# Crea un commit con el mensaje proporcionado
git commit -m "$commit_message"

# Empuja los cambios al repositorio remoto
git push origin "$branch_name"

# Verifica si el push fue exitoso
if [ $? -ne 0 ]; then
  echo "Hubo un error al hacer push. Verifica los mensajes de error anteriores."
  exit 1
fi

echo "Repositorio actualizado exitosamente en la rama '$branch_name'."
