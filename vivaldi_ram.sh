#!/bin/sh

# Simples
psave="/initrd/mnt/dev_save"
n="/0.sesion.vivaldi"
ram="/tmp/vramfs"
aleat="$RANDOM"
vtn="/v$aleat"
ext=".xz.sfs"

# Compuestos
f="$n$ext"
sfs="$psave$f"
ramsfs="$ram$f"
dvt="$ram$vtn" # /tmp/vramfs/v0
vme="$dvt/merged"

# Programa
if [ -f "$ram/aleat.txt" ];then
	vtn="/v$(cat $ram/aleat.txt)"
	dvt="$ram$vtn" # /tmp/vramfs/v0
	vme="$dvt/merged"
else
	echo "$aleat" > "$ram/aleat.txt"
	echo "vtn '$vtn'"
	mkdir -pv "$ram"
	mount -t ramfs ramfs "$ram"
	cd "$ram"
	busybox rm -vf "$ramsfs" "$sfs.2.sfs"
	dd if="$sfs" of="$sfs.2.sfs"
	busybox cp -vf "$sfs.2.sfs" "$ramsfs"
	mkdir -pv "$dvt"
	cd "$dvt"
	montar_sfs_escritura.sh "$ramsfs"
	sleep 1
fi
echo "/usr/bin/vivaldi-stable --no-sandbox --user-data-dir='$vme' $@"
if [[ "$(mount | grep -E "$ram/v*[0-9]+/merged")" != "" ]];then
	/usr/bin/vivaldi-stable --no-sandbox --user-data-dir="$vme" $@
else
	echo "Error: El SFS no está montado."
fi
