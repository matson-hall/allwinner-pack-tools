#!/bin/bash


LINUX_ROOT=${PWD}/linux
BR_ROOT=${PWD}/buildroot
TOOLS_ROOT=${PWD}/tools
CROSS_COMPILE=arm-linux-gnueabihf-
PACK_ROOT=${PWD}/tools/pack
OUT_ROOT=${PWD}/out

build_prepare()
{
    rm -rf ${OUT_ROOT}
    mkdir ${OUT_ROOT}
}

build_linux()
{
    cd ${LINUX_ROOT}
    cp arch/arm/configs/cubieboard_defconfig .config
    make ARCH=arm LOADADDR=0x40008000  -j4 uImage modules
	cp ${LINUX_ROOT}/arch/arm/boot/uImage ${OUT_ROOT}/boot.img
	cp ${LINUX_ROOT}/arch/arm/boot/dts/sun4i-a10-cubieboard.dtb ${OUT_ROOT}/cb.dtb
}

build_br()
{
    cd ${BR_ROOT}
    make O=${OUT_ROOT}/br cubieboard_defconfig
    make O=${OUT_ROOT}/br LICHEE_GEN_ROOTFS=n

    echo "Regenerating rootfs"
    
    (
	cd $LINUX_ROOT
	make ARCH=arm modules_install INSTALL_MOD_PATH=${OUT_ROOT}/br/target
    )

    make O=${OUT_ROOT}/br target-generic-getty-busybox
    make O=${OUT_ROOT}/br target-finalize
    make O=${OUT_ROOT}/br LICHEE_GEN_ROOTFS=y rootfs-ext4
    cp ${OUT_ROOT}/br/images/rootfs.ext4 ${OUT_ROOT}/
}

build_pack()
{
    cd ${PACK_ROOT}
    ./pack -c sun4i -p linux -b cubieboard
}

#build_prepare
build_linux
build_br
build_pack




