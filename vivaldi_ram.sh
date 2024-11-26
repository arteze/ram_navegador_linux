#!/bin/sh

# Simples
psave="/initrd/mnt/dev_save"
n="/0.sesion.vivaldi"
ram="/tmp/vramfs"
vtn="/v$RANDOM"

# Compuestos
sfs="$psave$n.sfs"
ramsfs="$ram$n.sfs"
dvt="$ram$vtn" # /tmp/vramfs/v0
vme="$dvt/merged"

# Programa
mkdir -pv "$ram"
mount -t ramfs ramfs "$ram"
cd "$ram"
busybox rm -vf "$ramsfs" "$sfs.2.sfs"
busybox cp -vf "$sfs" "$sfs.2.sfs"
busybox cp -vf "$sfs.2.sfs" "$ramsfs"
mkdir -pv "$dvt"
cd "$dvt"
montar_sfs_escritura.sh "$ramsfs"
sleep 1
echo "/usr/bin/vivaldi-stable --no-sandbox --user-data-dir='$vme' $@"
/usr/bin/vivaldi-stable --no-sandbox --user-data-dir="$vme" $@
