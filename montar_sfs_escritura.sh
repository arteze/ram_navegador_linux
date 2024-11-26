#!/bin/sh

# Código creado por ChatGPT
# Usando el comando unionfs-fuse para montar un SFS en modo escritura con 3 capas de directorios

# Verifica si los comandos necesarios están instalados
if ! command -v mount &>/dev/null || ! command -v unionfs-fuse &>/dev/null; then
    echo "Error: Asegúrate de tener 'mount' y 'unionfs-fuse' instalados."
    echo "Instala unionfs-fuse con: sudo apt install unionfs-fuse"
    exit 1
fi

# Archivos y directorios
SFS_FILE="$1"           # Archivo SFS (primer argumento del script)
SFS_MOUNT_DIR="sfs_mount"  # Directorio donde se montará el SFS
UPPER_DIR="upper"          # Capa de escritura
MERGED_DIR="merged"        # Punto de montaje final

# Verifica que se pase un archivo SFS como argumento
if [ -z "$SFS_FILE" ]; then
    echo "Uso: $0 <archivo.sfs>"
    exit 1
fi

# Verifica que el archivo SFS exista
if [ ! -f "$SFS_FILE" ]; then
    echo "Error: No se encontró el archivo SFS '$SFS_FILE'."
    exit 1
fi

# Crea los directorios necesarios
mkdir -pv "$SFS_MOUNT_DIR" "$UPPER_DIR" "$MERGED_DIR"

# Monta el archivo SFS en modo solo lectura
echo "Montando el archivo SFS en '$SFS_MOUNT_DIR'..."
sudo mount -t squashfs -o loop,ro "$SFS_FILE" "$SFS_MOUNT_DIR"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo montar el archivo SFS."
    exit 1
fi

# Monta el sistema combinado con UnionFS
echo "Creando unión con UnionFS-FUSE en '$MERGED_DIR'..."
unionfs-fuse -o cow "${UPPER_DIR}=RW:${SFS_MOUNT_DIR}=RO" "$MERGED_DIR"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo crear la unión con UnionFS."
    sudo umount "$SFS_MOUNT_DIR"
    exit 1
fi

# Verifica el montaje exitoso
if mountpoint -q "$MERGED_DIR"; then
    echo "Sistema de archivos combinado montado exitosamente en '$MERGED_DIR'."
    echo "Capa de escritura: $UPPER_DIR"
    echo "Capa de solo lectura: $SFS_MOUNT_DIR (desde $SFS_FILE)"
else
    echo "Error: Algo falló durante el montaje."
    sudo umount "$SFS_MOUNT_DIR"
    exit 1
fi
