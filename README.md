# build
```bash
apt install gcc-12 g++-12 git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison sbsigntool clang lld llvm
bash prepare_kernels.sh
bash build_kernels.sh
bash package_kernels.sh
```
# kernel_info.sh
内核源码配置表（url / branch / commit / ksu / llvm），被 prepare_kernels.sh 与 build_kernels.sh 引用  
内核源可用 commit 锁定：设置 `["<版本>,commit"]`（当前 6.12 锁定为 6.12.30），设置后按该 commit 做 --depth=1 克隆，未设置则跟随分支最新提交

# diff_kernel_configs.sh
diff_kernel_configs.sh [版本] [commit_a] [commit_b]  
同一份 defconfig 在两个 commit 下各生成一次 out/.config 并对比（默认 a=锁定 commit、b=分支最新提交），报告写到 .config-diff/report.txt，用于发现被新内核 Kconfig 静默丢掉的选项

# prepare_kernels.sh
prepare_kernels.sh [clean|reset|all] [5.10|5.15|6.1|6.6|6.12|6.15]  
不带参数默认执行prepare_kernels.sh all

# build_kernels.sh
build_kernels.sh [5.10|5.15|6.1|6.6|6.12|6.15]  
不带参数则批量构建kernels下文件夹  
推荐添加 MOK私钥MOK.priv MOK证书MOK.cer

# package_kernels.sh
package_kernels.sh [5.10|5.15|6.1|6.6|6.12|6.15]  
不带参数则批量打包kernels下文件夹为tar.gz到out文件夹

# make.sh
make.sh $1 $@ 相当于 make -D ./kernels/$1 $@
