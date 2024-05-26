#!/bin/bash

# Función para mostrar el uso del script
function show_usage() {
  echo "Uso: $0 [-b nombre_de_la_rama] [-c 'mensaje del commit'] [-u 'url del repositorio remoto']"
  exit 1
}

# Valores por defecto
branch_name="main"
commit_message="Actualizando carpeta eth_forge"
remote_url=""

# Parsear los argumentos
while getopts ":b:c:u:" opt; do
  case $opt in
    b)
      branch_name=$OPTARG
      ;;
    c)
      commit_message=$OPTARG
      ;;
    u)
      remote_url=$OPTARG
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

# Verifica si se proporcionó una URL del repositorio remoto
if [ -z "$remote_url" ]; then
  show_usage
fi

# Inicializa Git LFS si no se ha hecho antes
git lfs install

# Asegurar que los archivos grandes están siendo rastreados por LFS
git lfs track "*.hdf5"
git lfs track "*.AppImage"

# Eliminar archivos grandes del historial
git filter-repo --path demo.hdf5 --path ethereum/ganache-2.7.1-linux-x86_64.AppImage --invert-paths

# Configurar el origen del repositorio
git remote remove origin
git remote add origin "$remote_url"

# Agregar los archivos y .gitattributes para LFS
git add .gitattributes
git add .

# Crea un commit con el mensaje proporcionado
git commit -m "$commit_message"

# Empuja los cambios al repositorio remoto
git push origin "$branch_name" --force --all

# Verifica si el push fue exitoso
if [ $? -ne 0 ]; then
  echo "Hubo un error al hacer push. Verifica los mensajes de error anteriores."
  exit 1
fi

echo "Repositorio actualizado exitosamente en la rama '$branch_name'."
