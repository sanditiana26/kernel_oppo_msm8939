#!/bin/bash
BUILD_START=$(date +"%s")
tcdir=${HOME}/android/TOOLS/GCC

[ -d "out" ] && rm -rf out && mkdir -p out || mkdir -p out

[ -d $tcdir ] && \
echo "ARM64 TC Present." || \
echo "ARM64 TC Not Present. Downloading..." | \
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 $tcdir/los-4.9-64

[ -d $tcdir ] && \
echo "ARM32 TC Present." || \
echo "ARM32 TC Not Present. Downloading..." | \
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 $tcdir/los-4.9-32

make O=out ARCH=arm64 lineageos_a37f_defconfig

PATH="$tcdir/los-4.9-64/bin:$tcdir/los-4.9-32/bin:${PATH}" \
make    O=out \
        ARCH=arm64 \
        CC="ccache $tcdir/los-4.9-64/bin/aarch64-linux-android-gcc" \
        CROSS_COMPILE=aarch64-linux-android- \
        CROSS_COMPILE_ARM32=arm-linux-androideabi- \
        CONFIG_NO_ERROR_ON_MISMATCH=y \
        CONFIG_DEBUG_SECTION_MISMATCH=y \
        -j$(nproc --all) || exit

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
  cp out/arch/arm64/boot/Image.gz-dtb anykernel3/
elif [ -f "out/arch/arm64/boot/Image.gz" ]; then
  cp out/arch/arm64/boot/Image.gz anykernel3/
else
  cp out/arch/arm64/boot/Image anykernel3/
fi

if [ -f "out/arch/arm64/boot/dt.img" ]; then
  cp out/arch/arm64/boot/dt.img anykernel3/
fi

( cd anykernel3; zip -r ../out/A37F_KERNEL_ASU_$(date +%d.%m.%Y).zip * -x 'LICENSE' 'README.md' 'dtbtool.c' )

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "\e[1;42mBuild completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.\e[0m"
