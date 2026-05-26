#!/bin/bash

if [ ! -d /home/runner/work ];then
    NTHREADS=$(nproc)
else
    NTHREADS=$(($(nproc)*4))
fi

root_dir=$(pwd)
mkdir -p out

if [ -z "$1" ]; then
	kernels=$(ls -d ./kernels/* | sed 's#./kernels/##g')
else
	kernels="$1"
fi

for kernel in $kernels; do

    if [ ! -f "./kernels/$kernel/out/arch/x86/boot/bzImage" ];then
        echo "The kernel $kernel has to be build first"
        exit 1
    fi

    mkdir -p tmp/$kernel
    cd ./kernels/$kernel || { echo "Failed to enter source directory for kernel $kernel"; exit 1; }
    kernel_version="$(file ./out/arch/x86/boot/bzImage | cut -d' ' -f9)"
    [ ! "$kernel_version" == "" ] || { echo "Failed to read version for kernel $kernel"; exit 1; }
    cp ./out/arch/x86/boot/bzImage $root_dir/tmp/$kernel/vmlinuz-"$kernel_version" || { echo "Failed to copy the kernel $kernel"; exit 1; }
    make -j"$NTHREADS" O=out INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=$root_dir/tmp/$kernel modules_install || { echo "Failed to install modules for kernel $kernel"; exit 1; }

    mkdir -p $root_dir/tmp/$kernel/usr/src/linux-headers-"$kernel_version" || { echo "Failed to create the linux-headers directory for kernel $kernel"; exit 1; }
    cp -r ./headers/* $root_dir/tmp/$kernel/usr/src/linux-headers-"$kernel_version" || { echo "Failed to replace the build directory for kernel $kernel"; exit 1; }

    cd $root_dir/tmp/$kernel || { echo "Failed to enter directory for kernel $kernel"; exit 1; }
    rm -rf lib/modules/*/build lib/modules/*/source
    tar zcf $root_dir/out/kernel-"$kernel_version".tar.gz * --owner=0 --group=0 || { echo "Failed to create archive for kernel $kernel"; exit 1; }
    cd $root_dir || { echo "Failed to cleanup for kernel $kernel"; exit 1; }
    rm -rf ./tmp || { echo "Failed to cleanup for kernel $kernel"; exit 1; }

done
