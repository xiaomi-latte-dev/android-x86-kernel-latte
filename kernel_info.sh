#!/bin/bash

# 内核源码配置表
#   <版本>,url    仓库地址
#   <版本>,branch 跟踪分支（未设置 commit 时用它克隆）
#   <版本>,commit 锁定提交，设置后按 commit 做 --depth=1 克隆
#   <版本>,ksu    非 KernelSU 内核，需集成 BakaSU
#   <版本>,llvm   是否使用 LLVM=1（默认 true）

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
	["6.12,commit"]="5bf4b91e3333746223570f261f426fe5a77d4f13" # 6.12.30
	["6.15,url"]=$GITHUB_URL/android-generic/kernel-zenith
	["6.15,branch"]="6.15"
	# ["6.18,url"]=$GITHUB_URL/android-generic/kernel-zenith
	# ["6.18,branch"]="6.18"
)
