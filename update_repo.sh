#!/bin/bash

# Verifica si se proporcionó un mensaje de commit y una rama
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Uso: $0 'mensaje del commit' 'nombre de la rama'"
  exit 1
fi

# Almacena el mensaje del commit y el nombre de la rama
commit_message="$1"
branch_name="$2"

# Navega al directorio del repositorio (opcional)
# cd /ruta/al/repositorio

# Agrega todos los cambios al área de staging
git add .

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