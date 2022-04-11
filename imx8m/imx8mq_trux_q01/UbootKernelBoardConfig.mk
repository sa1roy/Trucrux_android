TARGET_BOOTLOADER_POSTFIX := bin
UBOOT_POST_PROCESS := true

TARGET_BOOTLOADER_CONFIG := \
         imx8mq-trux-q01-uuu:imx8mq_trux_android_uuu_defconfig \
	 imx8mq-trux-q01:imx8mq_trux_android_defconfig 
#	 imx8mm-trusty-secure-unlock:imx8mq_trux_android_trusty_secure_unlock_defconfig \
#	 imx8mm-trusty-dual:imx8mq_trux_android_trusty_dual_defconfig

# iMX8MQ kernel defconfig
TARGET_KERNEL_DEFCONFIG := imx8_trux_android_defconfig
#TARGET_KERNEL_ADDITION_DEFCONF ?= android_addition_defconfig

# absolute path is used, not the same as relative path used in AOSP make
TARGET_DEVICE_DIR := $(patsubst %/, %, $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))

# define bootloader rollback index
BOOTLOADER_RBINDEX ?= 0

