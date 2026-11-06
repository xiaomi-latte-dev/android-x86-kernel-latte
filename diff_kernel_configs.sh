#!/bin/bash
# 对比同一份 defconfig 在两个内核 commit 下生成的 out/.config
# 用途：找出被新内核 Kconfig 依赖变化静默丢弃的选项
#       例：6.12.77 的 CONFIG_ASHMEM 变成 depends on SHMEM && RUST，没装 rustc 就会被丢掉
#
# 用法：
#   ./diff_kernel_configs.sh                      # 6.12：锁定 commit vs 分支最新提交
#   ./diff_kernel_configs.sh 6.15
#   ./diff_kernel_configs.sh 6.12 <commit_a> <commit_b>
#   DIFF_ONLY=1 ./diff_kernel_configs.sh 6.12     # 复用 .config-diff 下已有的 a.config/b.config 重新出报告

. ./kernel_info.sh

version=${1:-6.12}
commit_a=${2:-${kernel_info["$version,commit"]}}
commit_b=${3:-${kernel_info["$version,branch"]}}
url=${kernel_info["$version,url"]}

if [ -z "$url" ] || [ -z "$commit_a" ] || [ -z "$commit_b" ]; then
	echo "版本 $version 的 url/commit/branch 配置不全，见 kernel_info.sh"
	exit 1
fi

config_file=./kernel-patches/${version}_defconfig
[ -f "$config_file" ] || config_file=./kernel-patches/mipad2_defconfig

work=.config-diff
tree=$work/$version
mkdir -p "$work"

render() {
	local ref=$1 out=$2
	if [ ! -d "$tree/.git" ]; then
		git init -q "$tree" || return 1
		git -C "$tree" remote add origin "$url" || return 1
	fi
	echo "== [$ref] 拉取"
	local n
	for n in 1 2 3; do
		git -C "$tree" -c http.version=HTTP/1.1 -c http.postBuffer=524288000 fetch --depth=1 origin "$ref" && break
		rm -f "$tree/.git/shallow.lock" "$tree/.git/index.lock"
		[ "$n" = 3 ] && { echo "拉取 $ref 失败（已重试 3 次）"; return 1; }
		echo "  第 $n 次失败，重试"
		sleep 5
	done
	git -C "$tree" checkout -fq FETCH_HEAD || return 1
	echo "== [$ref] 同步子模块"
	git -C "$tree" submodule update --init --recursive --depth=1 || return 1
	cp "$config_file" "$tree/arch/x86/configs/mipad2_defconfig" || return 1
	echo "== [$ref] 生成 .config"
	make -C "$tree" O=out ${LLVM:-LLVM=1} mipad2_defconfig >/dev/null || return 1
	cp "$tree/out/.config" "$out" || return 1
}

if [ -n "${DIFF_ONLY:-}" ] && [ -f "$work/a.config" ] && [ -f "$work/b.config" ]; then
	echo "== 复用 $work/a.config 与 $work/b.config"
else
	render "$commit_a" "$work/a.config" || { echo "a=$commit_a 失败"; exit 1; }
	render "$commit_b" "$work/b.config" || { echo "b=$commit_b 失败"; exit 1; }
fi

norm() {
	awk '
		/^CONFIG_[A-Za-z0-9_]+=/ { k=$0; sub(/=.*/, "", k); v=$0; sub(/^[^=]*=/, "", v); print k "\t" v; next }
		/^# CONFIG_[A-Za-z0-9_]+ is not set$/ { print $2 "\t<not set>" }
	' "$1" | LC_ALL=C sort -u -t "$(printf '\t')" -k1,1
}

norm "$work/a.config" > "$work/a.tsv"
norm "$work/b.config" > "$work/b.tsv"
join -t "$(printf '\t')" -a1 -a2 -e '<missing>' -o 0,1.2,2.2 "$work/a.tsv" "$work/b.tsv" > "$work/joined.tsv"

report=$work/report.txt
{
	echo "# $version   a=$commit_a   b=$commit_b"
	echo
	echo "## b 中被关掉（a 为 y/m 的最可疑）"
	awk -F'\t' '$2!="<not set>" && $2!="<missing>" && $3=="<not set>"' "$work/joined.tsv"
	echo
	echo "## b 中新启用"
	awk -F'\t' '$2=="<not set>" && $3!="<not set>"' "$work/joined.tsv"
	echo
	echo "## b 中已删除的符号"
	awk -F'\t' '$3=="<missing>"' "$work/joined.tsv"
	echo
	echo "## b 中新增的符号"
	awk -F'\t' '$2=="<missing>"' "$work/joined.tsv"
	echo
	echo "## 其他值变化"
	awk -F'\t' '$2!="<missing>" && $3!="<missing>" && $2!=$3 && $2!="<not set>" && $3!="<not set>"' "$work/joined.tsv"
} > "$report"

echo "报告: $report"
head -40 "$report"
