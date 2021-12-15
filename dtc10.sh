#
#  COMPILER KERNEL FOR SERVER
#

# Environment
GIT_TOKEN=
GIT_USERNAME=
TG_CHAT_ID=
TG_TOKEN=

# Kernel Sources
     rm -rf $HOME/buildkernel/mt6768
     git clone --depth=1 https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/kamukepoya/whatever_kernel -b test-kernel $HOME/buildkernel/mt6768
     rm -rf $HOME/buildkernel/dtc
     git clone --depth=1 https://github.com/NusantaraDevs/DragonTC -b daily/10.0 $HOME/buildkernel/dtc
     rm -rf $HOME/buildkernel/gcc64
     git clone --depth=1 https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 10 $HOME/buildkernel/gcc64
     rm -rf $HOME/buildkernel/gcc32
     git clone --depth=1 https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 10 $HOME/buildkernel/gcc32

# Main Declaration
KERNEL_ROOTDIR=$HOME/buildkernel/mt6768
CLANG_ROOTDIR=$HOME/buildkernel/dtc
KERNELNAME:[Whatever+1.5][DragonTC]
export KBUILD_BUILD_USER=Itsprof
export KBUILD_BUILD_HOST=serbermurah
IMAGE=$HOME/buildkernel/mt6768/out/arch/arm64/boot/Image.gz
DTBO=$HOME/buildkernel/mt6767/out/arch/arm64l/boot/dtbo.img
DTB=$HOME/buildkernel/mt6768/out/arch/arm64/boot/dts/mediatek/dtb
DATE=$(date +"%F-%S")
START=$(date +"%s")
PATH="$HOME/buildkernel/dtc/bin:$HOME/buildkernel/gcc64/bin:$HOME/buildkernel/gcc32/bin:${PATH}"

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

# Compile
tg_post_msg "<b>Compiled has started</b>"
tg_post_msg "<b>Builder Name :</b> <code>${KBUILD_BUILD_USER}</code>%0A<b>Builder Host :</b> <code>${KBUILD_BUILD_HOST}</code>%0A<b>Clang Version :</b> <code>DragonTC 10</code>%0A<b>Clang Rootdir :</b> <code>${CLANG_ROOTDIR}</code>%0A<b>Kernel Rootdir :</b> <code>${KERNEL_ROOTDIR}</code>"
compile(){
cd $HOME/buildkernel/mt6768
make -j$(nproc) O=out ARCH=arm64 merlin_defconfig
make -j$(nproc) ARCH=arm64 O=out \
    CC=clang \
    AS=llvm-as \
    LD=ld.lld \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-zyc-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-zyc-linux-gnueabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
   fi
      cd $HOME/buildkernel/mt6768/out/arch/arm64/boot/dts/mediatek && mv mt6768.dtb dtb
      cd -
  git clone --depth=1 https://github.com/kamukepoya/AnyKernel-nih AnyKernel
	cp $IMAGE AnyKernel
        cp $DTBO AnyKernel
        cp $DTB AnyKernel
}

# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b> | <b>DTC</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 $KERNELNAME-$DATE.zip *
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
