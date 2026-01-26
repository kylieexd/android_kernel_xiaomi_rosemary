#!/bin/bash
SECONDS=0
set -e

# Set kernel path
KERNEL_PATH="out/arch/arm64/boot"

# Set kernel file
OBJ="${KERNEL_PATH}/Image"
GZIP="${KERNEL_PATH}/Image.gz"
CAT="${KERNEL_PATH}/Image.gz-dtb"

# Set kernel name
DATE="$(TZ=Asia/Jakarta date +%Y%m%d%H%M)"
KERNEL_NAME="rethinking4.19-${DATE}.zip"

# Create anykernel
rm -rf anykernel
git clone https://github.com/kylieeXD/AK3-Rosemary.git anykernel

function KERNEL_COMPILE() {
	# Set environment variables
	export USE_CCACHE=1
	export KBUILD_BUILD_HOST=builder
	export KBUILD_BUILD_USER=khayloaf

	# Create output directory and do a clean build
	rm -rf out && mkdir -p out

	# Download clang if not present
	if [[ ! -d "clang" ]]; then mkdir -p clang
		wget https://github.com/Impqxr/aosp_clang_ci/releases/download/13289611/clang-13289611-linux-x86.tar.xz -O clang.tar.gz
		tar -xf clang.tar.gz -C clang && if [ -d clang/clang-* ]; then mv clang/clang-*/* clang; fi && rm -rf clang.tar.gz
	fi

	# Add clang bin directory to PATH
	export PATH="${PWD}/clang/bin:$PATH"

	# Make the config
	make O=out ARCH=arm64 rosemary_defconfig

	# Build the kernel with clang and log output
	make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- LLVM=1 LLVM_IAS=1 2>&1 | tee -a out/compile.log
}

function KERNEL_RESULT() {
	# Check if build is successful
	if [ ! -f "$OBJ" ] || [ ! -f "$GZIP" ] || [ ! -f "$CAT" ]; then
		exit 1
	fi

	# Copying image
	cp "$CAT" "$1/kernels/"

	# Created zip kernel
	cd "$1" && zip -r9 "$2" *

	# Upload kernel
	curl -T "$2" -u :dc4f2d6d-ef86-4241-af44-44f311a0ecb9 https://pixeldrain.com/api/file/

	# Back to kernel root
	cd -
}

# Run functions for R variant
KERNEL_COMPILE "$1"
KERNEL_RESULT anykernel "$KERNEL_NAME"

# Done bang
echo -e "Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !\n"
