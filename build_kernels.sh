#!/bin/bash
. ./prepare_kernels.sh

if [ ! -d /home/runner/work ];then
	NTHREADS=$(nproc)
	MOK_KEY=MOK.key
	MOK_CERT=MOK.crt
else
	NTHREADS=$(($(nproc)*4))
	MOK_KEY=/persist/keys/MOK.priv
	MOK_CERT=/persist/keys/MOK.cer
fi

if [ -z "$1" ]; then
	kernels=$(ls -d ./kernels/* | sed 's#./kernels/##g')
else
	kernels="$1"
fi

export CCACHE_DIR=$(pwd)/.ccache
export USE_CCACHE=1

for kernel in $kernels; do
	echo "Building kernel $kernel"
	if [ "${kernel_info["$1,llvm"]:-true}" == "true" ];then
		LLVM="CFLAGS_KERNEL='-std=gnu11' LLVM=1"
	else
		LLVM="CFLAGS_KERNEL='-std=gnu89'"
	fi
	KCONFIG_NOTIMESTAMP=1 KBUILD_BUILD_TIMESTAMP='' KBUILD_BUILD_USER=Qs315490 KBUILD_BUILD_HOST=localhost \
		make -C "./kernels/$kernel" -j"$NTHREADS" O=out $LLVM || { echo "Kernel build failed"; exit 1; }
	rm -f "./kernels/$kernel/out/source"
	if [ -f "$MOK_KEY" ] && [ -f "$MOK_CERT" ]; then
		echo "Signing kernel $kernel"
		mv "./kernels/$kernel/out/arch/x86/boot/bzImage"{,.unsigned} || { echo "Kernel signing failed"; exit 1; }
		sbsign --key "$MOK_KEY" --cert "$MOK_CERT" --output "./kernels/$kernel/out/arch/x86/boot/bzImage"{,.unsigned}  || { echo "Kernel signing failed"; exit 1; }
	fi
	echo "Including kernel $kernel headers"
	srctree="./kernels/$kernel"
	objtree="./kernels/$kernel/out"
	SRCARCH="x86"
	KCONFIG_CONFIG="$objtree/.config"
	destdir="$srctree/headers"
	mkdir -p "${destdir}"
	(
		cd "${srctree}"
		echo Makefile
		find "arch/${SRCARCH}" -maxdepth 1 -name 'Makefile*'
		find include scripts -type f -o -type l
		find "arch/${SRCARCH}" -name Kbuild.platforms -o -name Platform
		find "arch/${SRCARCH}" -name include -o -name scripts -type d
	) | tar -c -f - -C "${srctree}" -T - | tar -xf - -C "${destdir}"
	{
		cd "${objtree}"
		if grep -q "^CONFIG_OBJTOOL=y" include/config/auto.conf; then
			echo tools/objtool/objtool
		fi
		find "arch/${SRCARCH}/include" Module.symvers include scripts -type f
		if grep -q "^CONFIG_GCC_PLUGINS=y" include/config/auto.conf; then
			find scripts/gcc-plugins -name '*.so'
		fi
	} | tar -c -f - -C "${objtree}" -T - | tar -xf - -C "${destdir}"
	cp "${KCONFIG_CONFIG}" "${destdir}/.config"
done

