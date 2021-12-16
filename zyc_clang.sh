# Environment
GIT_USERNAME=kamukepoya
GIT_TOKEN=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
TG_CHAT_ID=-1001594460781
TG_TOKEN=5033304308:AAFMZk06Th19PuhMKdigNNrhBn1Trkgjomg
LOG_DEBUG=1


# -------------------- # ---------------------- # -------------------------- # --------------------------- # -----------------#


# Clone kernel source
function kernel(){
  rm -rf $(pwd)/mt6768
  mkdir $(pwd)/mt6768
  git clone --depth=1 https://github.com/kamukepoya/whatever_kernel -b hmp-kernel $(pwd)/mt6768
}

# Clone ZyC_clang
function zyc(){
  rm -rf $(pwd)/ZyC-Clang*
  mkdir $(pwd)/clang
  wget -q  $(curl https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-14-link.txt 2>/dev/null) -O "ZyC-Clang-14.tar.gz"
  tar -xvf ZyC-Clang-14.tar.gz -C $(pwd)/clang
}


# -------------------- # ---------------------- # -------------------------- # --------------------------- # -----------------#


# Main 
KERNEL_ROOTDIR=$(pwd)/mt6768 # IMPORTANT ! Fill with your kernel source root directory.
CLANG_ROOTDIR=$(pwd)/clang
export KBUILD_BUILD_USER=Itsprof # Change with your own name or else.
KERNELNAME=[Whatever+1.5][ZycClang]
export KBUILD_BUILD_HOST=Github-work # Change with your own hostname.
IMAGE=$(pwd)/mt6768/out/arch/arm64/boot/Image.gz
DTBO=$(pwd)/mt6768/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/mt6768/out/arch/arm64/boot/dts/mediatek/dtb
DATE=$(date +"%F"-"%S")
START=$(date +"%s")
PATH="${PATH}:$(pwd)/clang/bin"


# -------------------- # ---------------------- # -------------------------- # --------------------------- # -----------------#


# Tg export
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"
}


# -------------------- # ---------------------- # -------------------------- # --------------------------- # -----------------#


# Compile kernel
tg_post_msg "<code>Compiled has started</code>"
function compile(){
cd $(pwd)/mt6768
make -j$(nproc) O=out ARCH=arm64 merlin_defconfig
make -j$(nproc) ARCH=arm64 O=out \
    CC=${CLANG_ROOTDIR}/bin/clang \
    NM=${CLANG_ROOTDIR}/bin/llvm-nm \
    LD=${CLANG_ROOTDIR}/bin/ld.lld \
    CROSS_COMPILE=${CLANG_ROOTDIR}/bin/aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=${CLANG_ROOTDIR}/bin/arm-linux-gnueabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
       exit 1
   fi
        cd $(pwd)/mt6768/out/arch/arm64/boot/dts/mediatek && mv mt6768.dtb dtb
        cd -
  git clone --depth=1 https://github.com/kamukepoya/AnyKernel-nih AnyKernel
	cp $IMAGE AnyKernel
               cp $DTBO AnyKernel
   cp $DTB AnyKernel
}


# -------------------- # ---------------------- # -------------------------- # --------------------------- # -----------------#


# Push 
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="✅Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Redmi Note 9 merlin</b> | <b>Use ZyC-Clang 14</b>"
}

# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
        exit 1
}

# Zipping kernel
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 $KERNELNAME-$DATE.zip *
    cd ..
}


# -------------------- # ---------------------- # -------------------------- # --------------------------- # -----------------#

kernel
zyc
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push

# -------------------- # ---------------------- # -------------------------- # --------------------------- # -----------------#
