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
fi
echo "vtn '$vtn'"
if [ ! -d /tmp/vramfs ];then
	mkdir -pv "$ram"
	mount -t ramfs ramfs "$ram"
	cd "$ram"
	busybox rm -vf "$ramsfs" "$sfs.2.sfs"
	busybox cp -vf "$sfs" "$sfs.2.sfs"
	busybox cp -vf "$sfs.2.sfs" "$ramsfs"
	mkdir -pv "$dvt"
	cd "$dvt"
	montar_sfs_escritura "$ramsfs"
	sleep 1
fi
echo "/usr/bin/vivaldi-stable --no-sandbox --user-data-dir='$vme' $@"
/usr/bin/vivaldi-stable --no-sandbox --user-data-dir="$vme" $@
