#!/bin/bash

# Verificar si se proporcionó la ruta del ícono
if [ -z "$1" ]; then
  echo "Uso: $0 /ruta/al/icono.png"
  exit 1
fi

# Ruta del ícono
ICON_PATH="$1"

# Verificar si el archivo del ícono existe
if [ ! -f "$ICON_PATH" ]; then
  echo "Error: No se encuentra el archivo '$ICON_PATH'"
  exit 1
fi

# Obtener el ID de la ventana actual
WIN_ID=$(xdotool getwindowfocus)

# Verificar si se obtuvo un ID válido
if [ -z "$WIN_ID" ]; then
  echo "Error: No se pudo obtener el ID de la ventana actual."
  exit 1
fi

# Cambiar el ícono de la ventana actual
xseticon -id "$WIN_ID" "$ICON_PATH"

if [ $? -eq 0 ]; then
  echo "Ícono cambiado con éxito para la ventana con ID $WIN_ID."
else
  echo "Error: No se pudo cambiar el ícono."
fi
