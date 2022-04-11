#!/bin/bash
set -e

#### Script version ####
SCRIPT_NAME=${0##*/}
readonly SCRIPT_VERSION="0.8"

#### Exports Variables ####
#### global variables ####
readonly ABSOLUTE_FILENAME=`readlink -e "$0"`
readonly ABSOLUTE_DIRECTORY=`dirname ${ABSOLUTE_FILENAME}`
readonly SCRIPT_POINT=`pwd`/sources/meta-trucrux/scripts/  #meta-trucrux-fslc/scripts/

ANDROID_SCRIPTS_PATH=${SCRIPT_POINT}/trux_mk_yocto_sdcard/trucrux_scripts
ANDROID_BUILD_ROOT=/media/tru-ser-01/Storage1_seagate/imx8/imx8mq/codesetup/Android/Android-11/android_build/

TEMP_DIR=./trux_tmp
ROOTFS_MOUNT_DIR=${TEMP_DIR}/rootfs

help() {
	bn=`basename $0`
	echo " Usage: MACHINE=<imx8mq-trux-q01|imx8mm-trux-q01|imx8mp-trux> $bn device_node"
	echo
}

case $MACHINE in
	"imx8mq-trux-q01")
		ANDROID_IMGS_PATH=${ANDROID_BUILD_ROOT}/out/target/product/imx8mq_trux_q01
		;;
	"imx8mp-trux")
		ANDROID_IMGS_PATH=${ANDROID_BUILD_ROOT}/out/target/product/trux_mx8mp
		;;
	"imx8mm-trux-q01")
		ANDROID_IMGS_PATH=${ANDROID_BUILD_ROOT}/out/target/product/imx8mm_trux_q01
		;;
	*)
		help
		exit 1
esac

MACHINE=$MACHINE ${SCRIPT_POINT}/trux_mk_yocto_sdcard/trux-create-yocto-sdcard.sh "$@"

# Parse command line only to get ${node} and ${part}
moreoptions=1
node="na"
cal_only=0

while [ "$moreoptions" = 1 -a $# -gt 0 ]; do
	case $1 in
	    -h) ;;
	    -s) ;;
	    -a) ;;
	    -r) shift;
	    ;;
	    -n) shift;
	    ;;
	    *)  moreoptions=0; node=$1 ;;
	esac
	[ "$moreoptions" = 1 ] && shift
done

part=""
if [[ $node == *mmcblk* ]] || [[ $node == *loop* ]] ; then
	part="p"
fi

echo "========================================================"
echo "= Trucrux recovery SD card creation script - Android ="
echo "========================================================"

function mount_parts
{
	mkdir -p ${ROOTFS_MOUNT_DIR}
	sync
	mount ${node}${part}1  ${ROOTFS_MOUNT_DIR}
}

function unmount_parts
{
	umount ${ROOTFS_MOUNT_DIR}
	rm -rf ${TEMP_DIR}
}

function copy_android
{
	echo
	echo "Copying Android images to /opt/images/"
	mkdir -p ${ROOTFS_MOUNT_DIR}/opt/images/Android

	cp ${ANDROID_IMGS_PATH}/u-boot-${MACHINE}*.imx	${ROOTFS_MOUNT_DIR}/opt/images/Android/
	cp ${ANDROID_IMGS_PATH}/boot.img			${ROOTFS_MOUNT_DIR}/opt/images/Android/
	cp ${ANDROID_IMGS_PATH}/dtbo-*.img			${ROOTFS_MOUNT_DIR}/opt/images/Android/
	cp ${ANDROID_IMGS_PATH}/vbmeta-*.img			${ROOTFS_MOUNT_DIR}/opt/images/Android/

	if [[ "${MACHINE}" = "imx8qm-trux-som" ]]; then
		echo "Copying firmware images to /opt/images/"
		cp ${ANDROID_IMGS_PATH}/vendor/firmware/hdmitxfw.bin	${ROOTFS_MOUNT_DIR}/opt/images/Android/
		cp ${ANDROID_IMGS_PATH}/vendor/firmware/dpfw.bin	${ROOTFS_MOUNT_DIR}/opt/images/Android/
	fi

	if [ -e "${ANDROID_IMGS_PATH}/super.img" ]; then
		echo "Copying super image to /opt/images/"
		pv ${ANDROID_IMGS_PATH}/super.img >		${ROOTFS_MOUNT_DIR}/opt/images/Android/super.img
		sync | pv -t
	else
		echo "Copying system image to /opt/images/"
		pv ${ANDROID_IMGS_PATH}/system.img >		${ROOTFS_MOUNT_DIR}/opt/images/Android/system.img
		sync | pv -t
		echo "Copying vendor image to /opt/images/"
		pv ${ANDROID_IMGS_PATH}/vendor.img >		${ROOTFS_MOUNT_DIR}/opt/images/Android/vendor.img
		sync | pv -t
		echo "Copying product image to /opt/images/"
		pv ${ANDROID_IMGS_PATH}/product.img >		${ROOTFS_MOUNT_DIR}/opt/images/Android/product.img
		sync | pv -t
	fi
	if [ -e "${ANDROID_IMGS_PATH}/vendor_boot.img" ]; then
                echo "Copying super image to /opt/images/"
                pv ${ANDROID_IMGS_PATH}/vendor_boot.img >             ${ROOTFS_MOUNT_DIR}/opt/images/Android/vendor_boot.img
                sync | pv -t
	fi

#	if [[ "${MACHINE}" = "imx8mm-trux" ]]; then
#                echo "Copying M4 demo images to /opt/images/"
#                pv ${ANDROID_BUILD_ROOT}/device/trucrux/common/rpmsg_lite_pingpong_rtos_linux_remote.bin > \
#                            ${ROOTFS_MOUNT_DIR}/opt/images/Android/rpmsg_lite_pingpong_rtos_linux_remote.bin
#                pv ${ANDROID_BUILD_ROOT}/device/trucrux/common/rpmsg_lite_pingpong_rtos_linux_remote.elf > \
#                           ${ROOTFS_MOUNT_DIR}/opt/images/Android/rpmsg_lite_pingpong_rtos_linux_remote.elf
#                pv ${ANDROID_BUILD_ROOT}/device/trucrux/common/hello_world.elf > \
#                             ${ROOTFS_MOUNT_DIR}/opt/images/Android/hello_world.elf
#                sync | pv -t
#	elif [[ "${MACHINE}" = "imx8mq-trux" ]]; then
#                echo "Copying M4 demo images to /opt/images/"
#                pv ${ANDROID_BUILD_ROOT}/device/trucrux/imx8m/trux_mx8mq/cm_rpmsg_lite_pingpong_rtos_linux_remote.bin.debug > \
#				${ROOTFS_MOUNT_DIR}/opt/images/Android/cm_rpmsg_lite_pingpong_rtos_linux_remote.bin
#                pv ${ANDROID_BUILD_ROOT}/device/trucrux/imx8m/trux_mx8mq/cm_rpmsg_lite_pingpong_rtos_linux_remote.elf.debug > \
#				${ROOTFS_MOUNT_DIR}/opt/images/Android/rpmsg_lite_pingpong_rtos_linux_remote.elf
#
#                sync | pv -t
#	fi
}

function copy_android_scripts
{
	echo
	echo "Copying Android script"
	cp ${ANDROID_SCRIPTS_PATH}/mx8_install_android.sh		${ROOTFS_MOUNT_DIR}/usr/bin/install_android.sh
}

mount_parts
copy_android
copy_android_scripts

echo
echo "Syncing"
sync | pv -t

unmount_parts

echo
echo "Done"

exit 0
