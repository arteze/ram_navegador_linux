# ram_navegador_linux
Cómo usar navegadores basados en Chrome en la RAM en Linux

En este caso vamos a usar Vivaldi.

También se puede hacer lo mismo con otros navegadores, aunque hay que ingeniárselas un poco, cambiando cosas el script.

# Pasos

## Paso 1: Usar Vivaldi y configurarlo
Primero hay que usar Vivaldi normalmente, indicando la ruta de la sesión, en este caso nombramos a la sesión `0.vivaldi.sesion`, aunque podríamos nombrarla de otra manera.

Ejemplo:
```sh
/usr/bin/vivaldi-stable --no-sandbox --user-data-dir="/initrd/mnt/dev_save/0.sesion.vivaldi" $@
```

## Paso 2: Crear un SFS de la sesión
Para compactar toda la información, hacer un SFS de la carpeta de la sesión `/initrd/mnt/dev_save/0.sesion.vivaldi`.

Se puede usar `pcompress` en Puppy Linux, o el siguiente comando.

```sh
mksquashfs "/initrd/mnt/dev_save/0.sesion.vivaldi" "/initrd/mnt/dev_save/0.sesion.vivaldi.sfs" -no-strip -noappend -comp xz -b 1M -Xbcj ia64
```

## Paso 3: Usar Vivaldi en la RAM
El script `vivaldi_ram.sh` lo que hace es clonar el SFS para que no se dañen los datos originales, y luego copiarlo en la RAM, luego monta el SFS de la RAM en la RAM y monta 3 directorios que son las capas para que se pueda usar en modo escritura.

Las siguientes variables determinan la ubicación del SFS original.
```sh
# Simples
psave="/initrd/mnt/dev_save"
n="/0.sesion.vivaldi"
ram="/tmp/vramfs"
aleat="$RANDOM"
vtn="/v$aleat"
ext=".xz.sfs"
```
