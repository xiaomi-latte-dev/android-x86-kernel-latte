# build
```bash
apt install gcc-12 g++-12 git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison sbsigntool clang lld llvm
bash prepare_kernels.sh
bash build_kernels.sh
bash package_kernels.sh
```
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
