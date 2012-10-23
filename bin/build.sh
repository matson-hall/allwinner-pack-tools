#!/bin/bash

CB_UBOOT_ROOT=${PWD}/uboot-allwinner
CB_SUNXI_TOOLS_ROOT=${PWD}/sunxi-tools
CB_SUNXI_BIN_AR_ROOT=${PWD}/sunxi-bin-archive
CB_MKSUNXIBOOT_ROOT=${PWD}/mksunxiboot
CB_LINUX_ROOT=${PWD}/linux-allwinner
CB_BUILDROOT_ROOT=${PWD}/allwinner-buildroot
CB_OUTPUT_ROOT=$PWD/out
CB_TOOLS_ROOT=$PWD/allwinner-pack-tools

CROSS_COMPILE=arm-none-linux-gnueabi-
export OBJCOPY=${CROSS_COMPILE}objcopy

build_prepare()
{
    rm -rf $CB_OUTPUT_ROOT
    mkdir -pv $CB_OUTPUT_ROOT
}

build_buildroot()
{
    (
    cd $CB_BUILDROOT_ROOT

	if [ ! -e .config ]; then
    make cubieboard_defconfig
	fi

    make LICHEE_GEN_ROOTFS=n
    )
}

build_uboot()
{
    (
    cd $CB_UBOOT_ROOT
    make CROSS_COMPILE=${CROSS_COMPILE} distclean
    make CROSS_COMPILE=${CROSS_COMPILE} sun4i
    )
}

build_linux()
{
    (
    cd ${CB_LINUX_ROOT}
    cp arch/arm/configs/cubieboard_defconfig .config
    make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -j4 uImage modules
    make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} INSTALL_MOD_PATH=${CB_OUTPUT_ROOT} modules_install
    ${OBJCOPY} -R .note.gnu.build-id -S -O binary vmlinux bImage
    cp arch/arm/boot/uImage bImage ${CB_OUTPUT_ROOT}/
    cp rootfs/sun4i_rootfs.cpio.gz ${CB_OUTPUT_ROOT}/rootfs.cpio.gz
    )
}

build_pack()
{
    #cp ${CB_UBOOT_ROOT}/u-boot.bin ${CB_OUTPUT_ROOT}/
    cp ${CB_TOOLS_ROOT}/pack/chips/sun4i/wboot/bootfs/linux/u-boot.bin ${CB_OUTPUT_ROOT}/

    rm -rf ${CB_BUILDROOT_ROOT}/output/target/lib/modules
    cp -r ${CB_OUTPUT_ROOT}/lib/modules ${CB_BUILDROOT_ROOT}/output/target/lib/

    (cd ${CB_OUTPUT_ROOT}
    mkbootimg --kernel bImage \
	--ramdisk rootfs.cpio.gz \
	--board 'cubieboard' \
	--base 0x40000000 \
	-o boot.img
    )
    (cd ${CB_BUILDROOT_ROOT}
    make target-generic-getty-busybox; make target-finalize
    make LICHEE_GEN_ROOTFS=y rootfs-ext4
    )

    cp ${CB_BUILDROOT_ROOT}/output/images/rootfs.ext4 ${CB_OUTPUT_ROOT}/rootfs.ext4

    (cd ${CB_TOOLS_ROOT}/pack
     ./pack -c sun4i -p linux -b cubieboard
    )
}

build_pack2()
{
    (cd ${CB_TOOLS_ROOT}/pack
     ./pack -c sun4i -p linux -b cubieboard
    )
     
}

export PATH=${CB_TOOLS_ROOT}/bin:${CB_BUILDROOT_ROOT}/output/external-toolchain/bin:$PATH
build_prepare
build_buildroot
#build_uboot
build_linux
build_pack




