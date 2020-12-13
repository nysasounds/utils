#!/bin/bash
# Simple scripts to make kernel using Genkernel and gensplash

# Make sure perms in kernel build dir are sane
umask 022

RUNCONF="/proc/config.gz"

SRC_LINK=$(readlink /usr/src/linux)
DEFCONF="/usr/share/genkernel/arch/x86_64/kernel-config-${SRC_LINK#*linux-}"



usage() {
echo "
Usage Example:   $0 -m -i

-i               : Build initrd only
-m               : Invoke menuconfig
-f config_file   : Use config_file for .config
"
}


get_args() {
while getopts "imf:t" arg; do
case $arg in
	m)
	MENU="--menuconfig"
	;;
	i)
	TARGET="initrd"
	;;
	f)
	CONFIG="$OPTARG"
	;;
	?)
	usage
	exit 1
	;;
esac
done
TARGET=${TARGET:-"all"}
}


copy_runtime() {
if [ -z "$CONFIG" ] ; then
	echo "Copying current running config..."
	zcat ${RUNCONF} > ${DEFCONF} && echo "Run-time config copied :)" || echo "Run-time config failed to copy" 
else
	echo "Restoring config: $CONFIG"
	cat ${CONFIG} > ${DEFCONF} && echo "Config copied :)" || echo "Config failed to copy"
	GPCONF="/etc/kernels/kernel-config-x86_64-${SRC_LINK#*linux-}"
	if [ -f "$GPCONF" ] ; then
		echo "Stashing genkernel storged config for current kernel..."
		mv ${GPCONF}{,.bak} && echo "...done :)" || echo "Failed to stash config"
	fi
fi
}


make_kernel() {
echo "Building kernel with the following Genkernel options:
${MENU} ${TARGET}
"
/usr/bin/genkernel ${MENU} ${TARGET}
if [ $? -ne 0 ] ; then
	echo "Build failed..."
	exit 1
else
	echo "Build completed :)"
fi
}


grub() {
echo "Creating new Grub config..."
grub-mkconfig -o /boot/grub/grub.cfg && echo "...done  :-)" || echo "...failed grub config  :-("
#grub-install --efi-directory=/boot/efi
}



echo

get_args $*
copy_runtime
make_kernel
grub

echo



exit 0
