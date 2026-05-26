#!/bin/bash

NORMAL_COLOR='\e[0m'
BLUE_COLOR='\e[1;34m'
GREEN_COLOR='\e[1;32m'
RED_COLOR="\e[1;31m"

apply_patches()
{
	if [ ! -d "./kernels/$1" ]; then
		echo -e "${RED_COLOR}Kernel $1: directory not found, Skip$NORMAL_COLOR"
		return
	fi

	for path in ./kernel-patches/"$1"/*.tar.gz; do
		if [ ! -f "$path" ]; then
			echo -e "${BLUE_COLOR}Kernel $1: $path archive not found, Skip$NORMAL_COLOR"
			continue
		fi
		echo -e "${BLUE_COLOR}Extracting archive: $path$NORMAL_COLOR"
		tar -xzvf "$path" -C "./kernels/$1" || { echo -e "${RED_COLOR}Kernel $1: $path archive unpacking failed$NORMAL_COLOR"; exit 1; }
	done

	for patch in ./kernel-patches/"$1"/*.patch; do
		if [ ! -f "$patch" ]; then
			echo -e "${BLUE_COLOR}Kernel $1: $path patch not found, Skip$NORMAL_COLOR"
			continue
		fi
		echo -e "${BLUE_COLOR}Applying patch: $patch$NORMAL_COLOR"
		patch -d"./kernels/$1" -p1 --no-backup-if-mismatch -N < "$patch" || { echo -e "${RED_COLOR}Kernel $1 patch $patch failed$NORMAL_COLOR"; exit 1; }
	done
	echo -e "${GREEN_COLOR}Applying patch all done!$NORMAL_COLOR"
}

make_config()
{
	echo "Copy config for kernel $1"
	config_file=./kernel-patches/mipad2_defconfig
	if [ -f ./kernel-patches/${1}_defconfig ];then
		config_file=./kernel-patches/${1}_defconfig
	fi
	if [ "${kernel_info["$1,llvm"]:-true}" == "true" ];then
		LLVM="LLVM=1"
	fi
	cp $config_file ./kernels/$1/arch/x86/configs/mipad2_defconfig || { echo -e "${RED_COLOR}Kernel $1 configuration failed$NORMAL_COLOR"; exit 1; }
	make -C ./kernels/$1 O=out $LLVM mipad2_defconfig || { echo -e "${RED_COLOR}Kernel $1 configuration failed$NORMAL_COLOR"; exit 1; }
}

download_kernel(){
	kernel_remote_path=${kernel_info["$kernel,url"]}
	kernel_remote_branch=${kernel_info["$kernel,branch"]}
	echo -e "${BLUE_COLOR}kernel_remote_path   = $kernel_remote_path$NORMAL_COLOR"
	echo -e "${BLUE_COLOR}kernel_remote_branch = $kernel_remote_branch$NORMAL_COLOR"

	git clone --depth=1 --single-branch $kernel_remote_path -b $kernel_remote_branch --recursive ./kernels/$kernel || { echo -e "${RED_COLOR}Download kernel $kernel failed!$NORMAL_COLOR"; exit 1; }

	# 对于没有ksu内核，集成SukiSU-Ultra。非GKI模式
	ksu=${kernel_info["$kernel,ksu"]}
	if [ "$ksu" == "true" ];then
		echo -e "${BLUE_COLOR}Kernel $kernel is not KernelSU kernel, SukiSU-Ultra integration$NORMAL_COLOR"
		pushd ./kernels/$kernel
		rm -rf ./KernelSU
		curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash
		popd
	fi
}

download_and_patch_kernels()
{
	for kernel in $1; do
		download_kernel "$kernel"
		apply_patches "$kernel"
		make_config "$kernel"
	done
}

clean_kernel(){
	if [ -z "$1" ]; then
		echo -e "${RED_COLOR}Please specify the kernel version to clean$NORMAL_COLOR"
		return
	fi
	if [ "$1" == "all" ]; then
		echo -e "${RED_COLOR}clean ALL kernel? Are you sure? (y/n)$NORMAL_COLOR"
		read -r answer
		if [ "$answer" != "y" ]; then
			echo -e "${RED_COLOR}Clean all kernel canceled$NORMAL_COLOR"
			return
		fi
		rm -rf ./kernels/*
		return
	fi
	for kernel in $@; do
		echo -e "${BLUE_COLOR}Cleaning kernel $kernel$NORMAL_COLOR"
		rm -rf ./kernels/$kernel
	done
}

GITHUB_URL=https://github.com

declare -A kernel_info=(
	["5.10,url"]=$GITHUB_URL/android-generic/kernel_common
	["5.10,branch"]="kernel-5.10.70"
	["5.10,ksu"]="true"
	["5.10,llvm"]="false"
	["5.15,url"]=$GITHUB_URL/android-generic/kernel_common
	["5.15,branch"]="umbral-20230901"
	["5.15,llvm"]="false"
	["6.1,url"]=$GITHUB_URL/android-generic/kernel_common
	["6.1,branch"]="hm/gloria"
	["6.6,url"]=$GITHUB_URL/android-generic/kernel_common
	["6.6,branch"]="hm/crimson"
	["6.12,url"]=$GITHUB_URL/android-generic/kernel-zenith
	["6.12,branch"]="6.12"
	["6.15,url"]=$GITHUB_URL/android-generic/kernel-zenith
	["6.15,branch"]="6.15"
)

main(){
	command="$1"
	shift
	case "$command" in
		"clean")
			clean_kernel $@
			;;
		"reset")
			if [ -z "$@" ]; then
				echo -e "${RED_COLOR}Please specify the kernel version to download$NORMAL_COLOR"
				exit 1
			fi
			clean_kernel $@
			download_and_patch_kernels $@
			;;
		"all")
			download_and_patch_kernels ${@:-6.12}
			;;
		*)
			download_and_patch_kernels ${command:-6.12}
			;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    # echo "模式：直接执行 (Executed)"
    main $@
else
    # echo "模式：Source 导入 (Sourced)"
	true
fi
