#!/bin/bash

CURRENT_DIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

KERNEL_DIR=${CURRENT_DIR}/kernel
#KERNEL_VERSION="4.9.51-xenomai-ipipe"
XENOMAI_DIR=${CURRENT_DIR}/xenomai
IPIPE_PATCH=${CURRENT_DIR}/ipipe.patch
DEVICE_DIR=${CURRENT_DIR}/device
OUT_DIR=${CURRENT_DIR}/out

function patch_ipipe()
{
    cd ${XENOMAI_DIR}
    scripts/prepare-kernel.sh --linux=${KERNEL_DIR} --ipipe=${IPIPE_PATCH} --arch=x86_64
}

function build_kernel()
{
	mkdir -p ${OUT_DIR}

	cd ${KERNEL_DIR}
	local proc_num=`getconf _NPROCESSORS_ONLN`
	local arch="x86_64"
	local mod_path=${OUT_DIR}/modules

	ARCH=${arch} make x86_64_defconfig
	${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m .config ${DEVICE_DIR}/kernel.config
	ARCH=${arch} make EXTRAVERSION="-xenomai" -j ${proc_num} INSTALL_MOD_PATH=${mod_path} INSTALL_MOD_STRIP=1 bzImage modules
	ARCH=${arch} make EXTRAVERSION="-xenomai" -j ${proc_num} INSTALL_MOD_PATH=${mod_path} INSTALL_MOD_STRIP=1 bzImage modules_install

	cp ${KERNEL_DIR}/arch/x86/boot/bzImage ${OUT_DIR}/vmlinuz
	cp ${KERNEL_DIR}/System.map ${OUT_DIR}/System.map
	cp ${KERNEL_DIR}/.config ${OUT_DIR}/config

	CONCURRENCY_LEVEL=`getconf _NPROCESSORS_ONLN` MAKEFLAGS="CFLAGS=${COMMON_KERNEL_CFLAGS}" fakeroot make-kpkg --arch=amd64 --subarch=x86_64  --initrd --append-to-version=-xenomai kernel_image kernel_headers
	mv ${KERNEL_DIR}/../*.deb ${OUT_DIR}
}

patch_ipipe
build_kernel