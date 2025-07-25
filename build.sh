#!/bin/bash

## Variables
# Toolchains
AOSP_REPO="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/master"
AOSP_ARCHIVE="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master"
SD_REPO="https://github.com/ThankYouMario/proprietary_vendor_qcom_sdclang"
SD_BRANCH="14"
PC_REPO="https://github.com/kdrag0n/proton-clang"
LZ_REPO="https://gitlab.com/Jprimero15/lolz_clang.git"
RC_URL="https://github.com/kutemeikito/RastaMod69-Clang/releases/download/RastaMod69-Clang-20.0.0-release/RastaMod69-Clang-20.0.0.tar.gz"
GC_REPO="https://api.github.com/repos/greenforce-project/greenforce_clang/releases/latest"
ZC_REPO="https://raw.githubusercontent.com/ZyCromerZ/Clang/refs/heads/main/Clang-main-link.txt"
RV_REPO="https://api.github.com/repos/Rv-Project/RvClang/releases/latest"
GCC_REPO="https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9"
GCC64_REPO="https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9"

# AnyKernel3
AK3_URL="https://github.com/ProtonKernel/AnyKernel3"
AK3_BRANCH="a72q"

# Custom toolchain directory
if [[ -z "$CUST_DIR" ]]; then
    CUST_DIR="$WP/custom-toolchain"
else
    echo -e "\nINFO: Overriding custom toolchain path..."
fi

# Workspace
if [[ -d /workspace ]]; then
    WP="/workspace"
    IS_GP=1
else
    WP="$PWD"
    IS_GP=0
fi

if [[ ! -d drivers ]]; then
    echo -e "\nERROR: Please execute from top-level kernel tree\n"
    exit 1
fi

if [[ "$IS_GP" == "1" ]]; then
    export KBUILD_BUILD_USER="VelocityFox22"
    export KBUILD_BUILD_HOST="neox"
fi

# Other
KERNEL_URL="https://github.com/VelocityFox22/a725f-U-s8/blob/main/arch/arm64/configs/a72q_eur_open_defconfig"
SECONDS=0 # builtin bash timer
DATE="$(date '+%Y%m%d-%H%M')"
BUILD_HOST="$USER@$(hostname)"
# Paths
SD_DIR="$WP/sdclang"
AC_DIR="$WP/aospclang"
PC_DIR="$WP/protonclang"
RC_DIR="$WP/rm69clang"
LZ_DIR="$WP/lolzclang"
GCC_DIR="$WP/gcc"
GCC64_DIR="$WP/gcc64"
AK3_DIR="$WP/AnyKernel3"
GC_DIR="$WP/greenforceclang"
ZC_DIR="$WP/zycclang"
RV_DIR="$WP/rvclang"
KDIR="$(readlink -f .)"
USE_GCC_BINUTILS="0"
OUT_IMAGE="out/arch/arm64/boot/Image.gz-dtb"
OUT_DTBO="out/arch/arm64/boot/dts/qcom/atoll-ab-idp.dtb"

## Default values
CODENAME="a72q"
DEVICE="Galaxy A72"
DEFAULT_DEFCONFIG="vendor/lineage-a72q_defconfig"
DEFCONFIG="$DEFAULT_DEFCONFIG"
CLANG_TYPE="lolz"
PROTON_VER="v1.0"
BUILD_TYPE="Testing"
USE_CCACHE=1
DO_CLEAN=0
DO_MENUCONFIG=0
DO_KSU=0
DO_TG=0
DO_BASHUP=0
DO_FLTO=0
DO_REGEN=0
LOG_UPLOAD=1

## Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

## Functions
show_header() {
    clear
    echo -e "${BLUE}"
    echo -e "  ____  _             _   _ _   _ _ _ _   _            "
    echo -e " |  _ \| |_   _  ___| | | | | | | | | |_| |_ ___ _ __ "
    echo -e " | |_) | | | | |/ _ \ | | | | | | | | __| __/ _ \ '__|"
    echo -e " |  __/| | |_| |  __/ |_| | |_| | | | |_| ||  __/ |   "
    echo -e " |_|   |_|\__,_|\___|\___/ \___/|_|_|\__|\__\___|_|   "
    echo -e "${NC}"
    echo -e "${YELLOW}Kernel Builder for Samsung Galaxy A72${NC}"
    echo -e "${YELLOW}Linux Version: $(make kernelversion 2>/dev/null)${NC}"
    echo -e "==================================================="
    echo
}

show_menu() {
    show_header
    echo -e "${GREEN}1. Build Kernel${NC}"
    echo -e "${GREEN}2. Clean Build${NC}"
    echo -e "${GREEN}3. Toolchain Settings${NC}"
    echo -e "${GREEN}4. Build Options${NC}"
    echo -e "${GREEN}5. Upload Options${NC}"
    echo -e "${RED}6. Exit${NC}"
    echo
    read -p "Please enter your choice [1-6]: " choice
}

show_toolchain_menu() {
    show_header
    echo -e "${GREEN}Current Toolchain: ${YELLOW}$CLANG_TYPE${NC}"
    echo
    echo -e "${GREEN}1. AOSP Clang${NC}"
    echo -e "${GREEN}2. Snapdragon Clang${NC}"
    echo -e "${GREEN}3. Proton Clang${NC}"
    echo -e "${GREEN}4. RastaMod69 Clang${NC}"
    echo -e "${GREEN}5. Lolz Clang${NC}"
    echo -e "${GREEN}6. Greenforce Clang${NC}"
    echo -e "${GREEN}7. ZyC Clang${NC}"
    echo -e "${GREEN}8. RvClang${NC}"
    echo -e "${GREEN}9. Custom Toolchain${NC}"
    echo -e "${RED}10. Back to Main Menu${NC}"
    echo
    read -p "Please select toolchain [1-10]: " toolchain_choice
}

show_build_options() {
    show_header
    echo -e "${GREEN}Current Build Options:${NC}"
    echo -e " - KernelSU: ${YELLOW}$([ "$DO_KSU" -eq 1 ] && echo "Enabled" || echo "Disabled")${NC}"
    echo -e " - Full LTO: ${YELLOW}$([ "$DO_FLTO" -eq 1 ] && echo "Enabled" || echo "Disabled")${NC}"
    echo -e " - Menuconfig: ${YELLOW}$([ "$DO_MENUCONFIG" -eq 1 ] && echo "Enabled" || echo "Disabled")${NC}"
    echo -e " - Regenerate Config: ${YELLOW}$([ "$DO_REGEN" -eq 1 ] && echo "Enabled" || echo "Disabled")${NC}"
    echo -e " - Build Type: ${YELLOW}$BUILD_TYPE${NC}"
    echo
    echo -e "${GREEN}1. Toggle KernelSU${NC}"
    echo -e "${GREEN}2. Toggle Full LTO${NC}"
    echo -e "${GREEN}3. Toggle Menuconfig${NC}"
    echo -e "${GREEN}4. Toggle Config Regeneration${NC}"
    echo -e "${GREEN}5. Toggle Build Type${NC}"
    echo -e "${RED}6. Back to Main Menu${NC}"
    echo
    read -p "Please select option [1-6]: " build_opt_choice
}

show_upload_options() {
    show_header
    echo -e "${GREEN}Current Upload Options:${NC}"
    echo -e " - Telegram Upload: ${YELLOW}$([ "$DO_TG" -eq 1 ] && echo "Enabled" || echo "Disabled")${NC}"
    echo -e " - Bashupload: ${YELLOW}$([ "$DO_BASHUP" -eq 1 ] && echo "Enabled" || echo "Disabled")${NC}"
    echo -e " - Log Upload: ${YELLOW}$([ "$LOG_UPLOAD" -eq 1 ] && echo "Enabled" || echo "Disabled")${NC}"
    echo
    echo -e "${GREEN}1. Toggle Telegram Upload${NC}"
    echo -e "${GREEN}2. Toggle Bashupload${NC}"
    echo -e "${GREEN}3. Toggle Log Upload${NC}"
    echo -e "${RED}4. Back to Main Menu${NC}"
    echo
    read -p "Please select option [1-4]: " upload_opt_choice
}

install_deps_deb() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    UB_DEPLIST="lz4 brotli flex bc cpio kmod ccache zip libtinfo5 python3"
    if grep -q "Ubuntu" /etc/os-release; then
        sudo apt update -qq
        sudo apt install $UB_DEPLIST -y
    else
        echo -e "${YELLOW}INFO: Your distro is not Ubuntu, skipping dependencies installation...${NC}"
        echo -e "${YELLOW}INFO: Make sure you have these dependencies installed before proceeding: $UB_DEPLIST${NC}"
    fi
}

get_toolchain() {
    local toolchain_type="$1"
    local toolchain_dir=""

    case "$toolchain_type" in
        aosp)
            toolchain_dir="$AC_DIR"
            USE_GCC_BINUTILS=1
            if [[ ! -d "$toolchain_dir" ]]; then
                echo -e "\n${YELLOW}INFO: AOSP Clang not found! Cloning to $toolchain_dir...${NC}"
                CURRENT_CLANG=$(curl -s "$AOSP_REPO" | grep -oE "clang-r[0-9a-f]+" | sort -u | tail -n1)
                if ! curl -LSsO "$AOSP_ARCHIVE/$CURRENT_CLANG.tar.gz"; then
                    echo -e "\n${RED}ERROR: Cloning failed! Aborting...${NC}"
                    exit 1
                fi
                mkdir -p "$toolchain_dir" && tar -xf ./*.tar.gz -C "$toolchain_dir" && rm ./*.tar.gz
                touch "$toolchain_dir/bin/aarch64-linux-gnu-elfedit" && chmod +x "$toolchain_dir/bin/aarch64-linux-gnu-elfedit"
                touch "$toolchain_dir/bin/arm-linux-gnueabi-elfedit" && chmod +x "$toolchain_dir/bin/arm-linux-gnueabi-elfedit"
            fi
            ;;
        sdclang)
            toolchain_dir="$SD_DIR"
            if [[ ! -d "$toolchain_dir" ]]; then
                echo -e "${YELLOW}INFO: SD Clang not found! Cloning to $toolchain_dir...${NC}"
                if ! git clone -q -b "$SD_BRANCH" --depth=1 "$SD_REPO" "$toolchain_dir"; then
                    echo -e "${RED}ERROR: Cloning failed! Aborting...${NC}"
                    exit 1
                fi
            fi
            ;;
        proton)
            toolchain_dir="$PC_DIR"
            if [[ ! -d "$toolchain_dir" ]]; then
                echo -e "${YELLOW}INFO: Proton Clang not found! Cloning to $toolchain_dir...${NC}"
                if ! git clone -q --depth=1 "$PC_REPO" "$toolchain_dir"; then
                    echo -e "${RED}ERROR: Cloning failed! Aborting...${NC}"
                    exit 1
                fi
            fi
            ;;
        rm69)
            toolchain_dir="$RC_DIR"
            if [[ ! -d "$toolchain_dir" ]]; then
                echo -e "${YELLOW}INFO: RastaMod69 Clang not found! Cloning to $toolchain_dir...${NC}"
                wget -q --show-progress "$RC_URL" -O "$WP/RastaMod69-clang.tar.gz"
                if [[ $? -ne 0 ]]; then
                    echo -e "${RED}ERROR: Download failed! Aborting...${NC}"
                    rm -f "$WP/RastaMod69-clang.tar.gz"
                    exit 1
                fi
                rm -rf clang && mkdir -p "$toolchain_dir" && tar -xf "$WP/RastaMod69-clang.tar.gz" -C "$toolchain_dir"
                if [[ $? -ne 0 ]]; then
                    echo -e "${RED}ERROR: Extraction failed! Aborting...${NC}"
                    rm -f "$WP/RastaMod69-clang.tar.gz"
                    exit 1
                fi
                rm -f "$WP/RastaMod69-clang.tar.gz"
                echo -e "${YELLOW}INFO: RastaMod69 Clang successfully cloned to $toolchain_dir${NC}"
            fi
            ;;
        lolz)
            toolchain_dir="$LZ_DIR"
            if [[ ! -d "$toolchain_dir" ]]; then
                echo -e "${YELLOW}INFO: Lolz Clang not found! Cloning to $toolchain_dir...${NC}"
                if ! git clone -q --depth=1 "$LZ_REPO" "$toolchain_dir"; then
                    echo -e "${RED}ERROR: Cloning failed! Aborting...${NC}"
                    exit 1
                fi
            fi
            ;;
        greenforce)
            USE_GCC_BINUTILS=1
            toolchain_dir="$GC_DIR"
            if [[ ! -d "$toolchain_dir" ]]; then
                echo -e "${YELLOW}INFO: Greenforce Clang not found! Cloning to $toolchain_dir...${NC}"
                LATEST_RELEASE=$(curl -s $GC_REPO | grep "browser_download_url" | grep ".tar.gz" | cut -d '"' -f 4)
                if [[ -z "$LATEST_RELEASE" ]]; then
                    echo -e "${RED}ERROR: Failed to fetch the latest Greenforce Clang release! Aborting...${NC}"
                    exit 1
                fi
                if ! wget -q --show-progress -O "$WP/greenforce-clang.tar.gz" "$LATEST_RELEASE"; then
                    echo -e "${RED}ERROR: Download failed! Aborting...${NC}"
                    exit 1
                fi
                mkdir -p "$toolchain_dir"
                tar -xf "$WP/greenforce-clang.tar.gz" -C "$toolchain_dir"
                rm "$WP/greenforce-clang.tar.gz"
            fi
            ;;
        custom)
            toolchain_dir="$CUST_DIR"
            if [[ ! -d "$toolchain_dir" ]]; then
                echo -e "${RED}ERROR: Custom toolchain not found! Aborting...${NC}"
                echo -e "${YELLOW}INFO: Please provide a toolchain at $CUST_DIR or select a different toolchain${NC}"
                exit 1
            fi
            ;;
        zyc)
            toolchain_dir="$ZC_DIR"
            if [[ ! -d "$toolchain_dir" ]]; then
                echo -e "${YELLOW}INFO: ZyC Clang not found! Cloning to $toolchain_dir...${NC}"
                ZYC_VERSION_FILE="$WP/zyc-clang-version.txt"
                LATEST_VERSION=$(curl -s "$ZC_REPO" | head -n 1)
                if [[ -z "$LATEST_VERSION" ]]; then
                    echo -e "${YELLOW}INFO: Failed to check ZyC Clang version${NC}"
                else
                    if [[ -f "$ZYC_VERSION_FILE" ]]; then
                        CURRENT_VERSION=$(cat "$ZYC_VERSION_FILE")
                        if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
                            echo -e "${YELLOW}INFO: A new version of ZyC Clang is available: $LATEST_VERSION${NC}"
                            echo "$LATEST_VERSION" > "$ZYC_VERSION_FILE"
                        fi
                    else
                        echo "$LATEST_VERSION" > "$ZYC_VERSION_FILE"
                    fi
                fi

                if [[ -z "$LATEST_VERSION" ]]; then
                    echo -e "${RED}ERROR: Failed to fetch the latest ZyC Clang release! Aborting...${NC}"
                    exit 1
                fi
                if ! wget -q --show-progress -O "$WP/zyc-clang.tar.gz" "$LATEST_VERSION"; then
                    echo -e "${RED}ERROR: Download failed! Aborting...${NC}"
                    rm -f "$ZYC_VERSION_FILE"
                    exit 1
                fi
                mkdir -p "$toolchain_dir"
                if ! tar -xf "$WP/zyc-clang.tar.gz" -C "$toolchain_dir"; then
                    echo -e "${RED}ERROR: Extraction failed! Aborting...${NC}"
                    rm -f "$WP/zyc-clang.tar.gz" "$ZYC_VERSION_FILE"
                    exit 1
                fi
                rm "$WP/zyc-clang.tar.gz"
            fi
            ;;
        rv)
            toolchain_dir="$RV_DIR"
            if [[ ! -d "$toolchain_dir" ]]; then
                echo -e "${YELLOW}INFO: RvClang not found! Fetching the latest version...${NC}"
                LATEST_RELEASE=$(curl -s "$RV_REPO" | grep "browser_download_url" | grep ".tar.gz" | cut -d '"' -f 4)
                if [[ -z "$LATEST_RELEASE" ]]; then
                    echo -e "${RED}ERROR: Failed to fetch the latest RvClang release! Aborting...${NC}"
                    exit 1
                fi
                if ! wget -q --show-progress -O "$WP/rvclang.tar.gz" "$LATEST_RELEASE"; then
                    echo -e "${RED}ERROR: Download failed! Aborting...${NC}"
                    exit 1
                fi
                mkdir -p "$toolchain_dir"
                if ! tar -xf "$WP/rvclang.tar.gz" -C "$toolchain_dir"; then
                    echo -e "${RED}ERROR: Extraction failed! Aborting...${NC}"
                    rm -f "$WP/rvclang.tar.gz"
                    exit 1
                fi
                rm "$WP/rvclang.tar.gz"
                if [[ -d "$toolchain_dir/RvClang" ]]; then
                    mv "$toolchain_dir/RvClang"/* "$toolchain_dir/"
                    rmdir "$toolchain_dir/RvClang"
                fi
            fi
            ;;
        *)
            echo -e "${RED}ERROR: Unknown toolchain type: $toolchain_type${NC}"
            exit 1
            ;;
    esac

    if [[ "$USE_GCC_BINUTILS" == "1" ]]; then
        if [[ ! -d "$GCC_DIR" ]]; then
            echo -e "${YELLOW}INFO: GCC not found! Cloning to $GCC_DIR...${NC}"
            if ! git clone -q -b lineage-19.1 --depth=1 "$GCC_REPO" "$GCC_DIR"; then
                echo -e "${RED}ERROR: Cloning failed! Aborting...${NC}"
                exit 1
            fi
        fi
        if [[ ! -d "$GCC64_DIR" ]]; then
            echo -e "${YELLOW}INFO: GCC64 not found! Cloning to $GCC64_DIR...${NC}"
            if ! git clone -q -b lineage-19.1 --depth=1 "$GCC64_REPO" "$GCC64_DIR"; then
                echo -e "${RED}ERROR: Cloning failed! Aborting...${NC}"
                exit 1
            fi
        fi
    fi
}

prep_toolchain() {
    local toolchain_type="$1"
    local toolchain_dir=""

    case "$toolchain_type" in
        aosp)
            toolchain_dir="$AC_DIR"
            echo -e "${YELLOW}INFO: Toolchain: AOSP Clang${NC}"
            ;;
        sdclang)
            toolchain_dir="$SD_DIR/compiler"
            echo -e "${YELLOW}INFO: Toolchain: Snapdragon Clang${NC}"
            ;;
        proton)
            toolchain_dir="$PC_DIR"
            echo -e "${YELLOW}INFO: Toolchain: Proton Clang${NC}"
            ;;
        rm69)
            toolchain_dir="$RC_DIR"
            echo -e "${YELLOW}INFO: Toolchain: RastaMod69 Clang${NC}"
            ;;
        lolz)
            toolchain_dir="$LZ_DIR"
            echo -e "${YELLOW}INFO: Toolchain: Lolz Clang${NC}"
            ;;
        greenforce)
            toolchain_dir="$GC_DIR"
            echo -e "${YELLOW}INFO: Toolchain: Greenforce Clang${NC}"
            ;;
        zyc)
            toolchain_dir="$ZC_DIR"
            echo -e "${YELLOW}INFO: Toolchain: ZyC Clang${NC}"
            ;;
        custom)
            toolchain_dir="$CUST_DIR"
            echo -e "${YELLOW}INFO: Toolchain: Custom toolchain${NC}"
            ;;
        rv)
            toolchain_dir="$RV_DIR"
            echo -e "${YELLOW}INFO: Toolchain: RvClang${NC}"
            ;;
        *)
            echo -e "${RED}ERROR: Unknown toolchain type: $toolchain_type${NC}"
            exit 1
            ;;
    esac

    export PATH="${toolchain_dir}/bin:${PATH}"
    if [[ "$USE_GCC_BINUTILS" == "1" ]]; then
        export PATH="${GCC64_DIR}/bin:${GCC_DIR}/bin:${PATH}"
    fi
    KBUILD_COMPILER_STRING=$("$toolchain_dir/bin/clang" -v 2>&1 | head -n 1 | sed 's/(https..*//' | sed 's/ version//')
    export KBUILD_COMPILER_STRING

    if [[ "$USE_GCC_BINUTILS" == "1" ]]; then
        CCARM64_PREFIX="aarch64-linux-androideabi-"
        CCARM_PREFIX="arm-linux-androideabi-"
    else
        CCARM64_PREFIX="aarch64-linux-gnu-"
        CCARM_PREFIX="arm-linux-gnueabi-"
    fi
}

prep_build() {
    ## Prepare ccache
    if [[ "$USE_CCACHE" == "1" ]]; then
        echo -e "${YELLOW}INFO: ccache enabled${NC}"
        if [[ "$IS_GP" == "1" ]]; then
            export CCACHE_DIR="$WP/.ccache"
            ccache -M 10G
        else
            echo -e "${YELLOW}WARNING: Environment is not Gitpod, please make sure you setup your own ccache configuration!${NC}"
        fi
    fi

    # Show compiler information
    echo -e "${YELLOW}INFO: Compiler: $KBUILD_COMPILER_STRING${NC}\n"
}

build_kernel() {
    mkdir -p out
    make O=out ARCH=arm64 "$DEFCONFIG" $([[ "$DO_KSU" == "1" ]] && echo "vendor/ksu.config") 2>&1 | tee log.txt

    # Delete leftovers
    rm -f out/arch/arm64/boot/Image*
    rm -f out/arch/arm64/boot/dtbo*
    rm -f log.txt

    export LLVM=1 LLVM_IAS=1
    export ARCH=arm64

    if [[ "$DO_MENUCONFIG" == "1" ]]; then
        make O=out menuconfig
    fi

    if [[ "$DO_REGEN" == "1" ]]; then
        if [[ "$DO_KSU" = "1" ]]; then
             echo -e "${RED}ERROR: Can't regenerate with KSU argument${NC}"
             exit 1
        fi
        cp -f out/.config "arch/arm64/configs/$DEFCONFIG"
        echo -e "${GREEN}INFO: Configuration regenerated. Check the changes!${NC}"
        exit 0
    fi

    if [[ "$DO_FLTO" == "1" ]]; then
        scripts/config --file "$KDIR/out/.config" --enable CONFIG_LTO_CLANG
        scripts/config --file "$KDIR/out/.config" --disable CONFIG_THINLTO
    fi

    ## Start the build
    echo -e "\n${YELLOW}INFO: Starting compilation...${NC}\n"

    if [[ "$USE_CCACHE" == "1" ]]; then
        make -j$(nproc --all) O=out \
        CC="ccache clang" \
        CROSS_COMPILE="$CCARM64_PREFIX" \
        CROSS_COMPILE_ARM32="$CCARM_PREFIX" \
        CLANG_TRIPLE="aarch64-linux-gnu-" \
        READELF="llvm-readelf" \
        OBJSIZE="llvm-size" \
        OBJDUMP="llvm-objdump" \
        OBJCOPY="llvm-objcopy" \
        STRIP="llvm-strip" \
        NM="llvm-nm" \
        AR="llvm-ar" \
        HOSTAR="llvm-ar" \
        HOSTAS="llvm-as" \
        HOSTNM="llvm-nm" \
        LD="ld.lld" 2>&1 | tee log.txt
    else
        make -j$(nproc --all) O=out \
        CC="clang" \
        CROSS_COMPILE="$CCARM64_PREFIX" \
        CROSS_COMPILE_ARM32="$CCARM_PREFIX" \
        CLANG_TRIPLE="aarch64-linux-gnu-" \
        READELF="llvm-readelf" \
        OBJSIZE="llvm-size" \
        OBJDUMP="llvm-objdump" \
        OBJCOPY="llvm-objcopy" \
        STRIP="llvm-strip" \
        NM="llvm-nm" \
        AR="llvm-ar" \
        HOSTAR="llvm-ar" \
        HOSTAS="llvm-as" \
        HOSTNM="llvm-nm" \
        LD="ld.lld" 2>&1 | tee log.txt
    fi
}

post_build() {
    ## Check if the kernel binaries were built.
    if [ -f "$OUT_IMAGE" ]; then
        echo -e "\n${GREEN}INFO: Kernel compiled succesfully! Zipping up...${NC}"
    else
        echo -e "\n${RED}ERROR: Kernel files not found! Compilation failed?${NC}"
        echo -e "\n${YELLOW}INFO: Uploading log to bashupload.com${NC}\n"
        curl -T log.txt bashupload.com
        exit 1
    fi

    # If local AK3 copy exists, assume testing.
    if [[ -d "$AK3_DIR" ]]; then
        AK3_TEST=1
        echo -e "\n${YELLOW}INFO: AK3_TEST flag set because local AnyKernel3 dir was found${NC}"
    else
        if ! git clone -q --depth=1 -b "$AK3_BRANCH" "$AK3_URL" "$AK3_DIR"; then
            echo -e "\n${RED}ERROR: Failed to clone AnyKernel3!${NC}"
            exit 1
        fi
    fi

    ## Copy the built binaries
    cp "$OUT_IMAGE" "$AK3_DIR"
    cp "$OUT_DTBO" "$AK3_DIR"
    rm -f *zip

    ## Prepare kernel flashable zip
    cd "$AK3_DIR"
    git checkout "$AK3_BRANCH" &> /dev/null
    zip -r9 "$ZIP_PATH" * -x '*.git*' README.md *placeholder
    cd ..
    rm -rf "$AK3_DIR"
    echo -e "\n${GREEN}INFO: Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !${NC}"
    echo -e "${GREEN}Zip: $ZIP_PATH${NC}"
    echo -e " "
    if [[ "$AK3_TEST" == "1" ]]; then
        echo -e "\n${YELLOW}INFO: Skipping deletion of AnyKernel3 dir because test flag is set${NC}"
    else
        rm -rf "$AK3_DIR"
    fi
    cd "$KDIR"
}

upload() {
    if [[ "$DO_BASHUP" == "1" ]]; then
        echo -e "\n${YELLOW}INFO: Uploading to bashupload.com...${NC}\n"
        curl -T "$ZIP_PATH" bashupload.com; echo
    fi

    if [[ "$DO_TG" == "1" ]]; then
        echo -e "\n${YELLOW}INFO: Uploading to Telegram...${NC}\n"
        
        # Prepare caption
        CAPTION_BUILD="Build info:
*Device*: \`${DEVICE} [${CODENAME}]\`
*Kernel Version*: \`${LINUX_VER}\`
*Compiler*: \`${KBUILD_COMPILER_STRING}\`
*Linker*: \`$("${LINKER}" -v | head -n1 | sed -E 's/\([^)]*\)//g; s/  */ /g; s/^ //; s/ $//')\`
*Build host*: \`${BUILD_HOST}\`
*Branch*: \`$(git rev-parse --abbrev-ref HEAD)\`
*Commit*: [($(git rev-parse HEAD | cut -c -7))]($(echo $KERNEL_URL)/commit/$(git rev-parse HEAD))
*Build type*: \`$BUILD_TYPE\`
*Clean build*: \`$([ "$DO_CLEAN" -eq 1 ] && echo Yes || echo No)\`
"

        # Upload file
        MD5=$(md5sum "$ZIP_PATH" | cut -d' ' -f1)
        curl -fsSL -X POST -F document=@"$ZIP_PATH" https://api.telegram.org/bot"${TELEGRAM_BOT_TOKEN}"/sendDocument \
            -F "chat_id=${TELEGRAM_CHAT_ID}" \
            -F "parse_mode=Markdown" \
            -F "disable_web_page_preview=true" \
            -F "caption=${CAPTION_BUILD}*MD5*: \`$MD5\`" &>/dev/null
        
        echo -e "${GREEN}INFO: Done!${NC}"
    fi
    
    if [[ "$LOG_UPLOAD" == "1" ]]; then
        echo -e "\n${YELLOW}INFO: Uploading log to bashupload.com${NC}\n"
        curl -T log.txt bashupload.com
    fi
}

clean_build() {
    echo -e "${YELLOW}Cleaning build...${NC}"
    make O=out clean
    make O=out mrproper
}

clean_tmp() {
    echo -e "${YELLOW}Cleaning temporary files...${NC}"
    rm -f "$OUT_IMAGE"
    rm -f "$OUT_DTBO"
}

## Main Program
install_deps_deb

while true; do
    show_menu
    case $choice in
        1) # Build Kernel
            echo -e "\n${GREEN}Starting build process...${NC}"
            
            # Get toolchain
            get_toolchain "$CLANG_TYPE"
            prep_toolchain "$CLANG_TYPE"
            
            # Prepare build
            prep_build
            
            # Clean if needed
            if [[ "$DO_CLEAN" == "1" ]]; then
                clean_build
            fi
            
            # Build kernel
            build_kernel
            post_build
            
            # Upload if needed
            if [[ "$DO_TG" == "1" || "$DO_BASHUP" == "1" ]]; then
                upload
            fi
            
            # Clean temp files
            clean_tmp
            
            echo -e "\n${GREEN}Build process completed!${NC}"
            read -p "Press any key to continue..." -n1 -s
            ;;
        2) # Clean Build
            echo -e "\n${YELLOW}Cleaning build...${NC}"
            clean_build
            echo -e "${GREEN}Clean completed!${NC}"
            read -p "Press any key to continue..." -n1 -s
            ;;
        3) # Toolchain Settings
            while true; do
                show_toolchain_menu
                case $toolchain_choice in
                    1) CLANG_TYPE="aosp" ;;
                    2) CLANG_TYPE="sdclang" ;;
                    3) CLANG_TYPE="proton" ;;
                    4) CLANG_TYPE="rm69" ;;
                    5) CLANG_TYPE="lolz" ;;
                    6) CLANG_TYPE="greenforce" ;;
                    7) CLANG_TYPE="zyc" ;;
                    8) CLANG_TYPE="rv" ;;
                    9) 
                        read -p "Enter path to custom toolchain: " CUST_DIR
                        CLANG_TYPE="custom" 
                        ;;
                    10) break ;;
                    *) echo -e "${RED}Invalid option!${NC}" ;;
                esac
                echo -e "${GREEN}Toolchain set to: ${YELLOW}$CLANG_TYPE${NC}"
                sleep 1
            done
            ;;
        4) # Build Options
            while true; do
                show_build_options
                case $build_opt_choice in
                    1) DO_KSU=$((1-DO_KSU)) ;;
                    2) DO_FLTO=$((1-DO_FLTO)) ;;
                    3) DO_MENUCONFIG=$((1-DO_MENUCONFIG)) ;;
                    4) DO_REGEN=$((1-DO_REGEN)) ;;
                    5) 
                        if [[ "$BUILD_TYPE" == "Testing" ]]; then
                            BUILD_TYPE="Release"
                        else
                            BUILD_TYPE="Testing"
                        fi
                        ;;
                    6) break ;;
                    *) echo -e "${RED}Invalid option!${NC}" ;;
                esac
            done
            ;;
        5) # Upload Options
            while true; do
                show_upload_options
                case $upload_opt_choice in
                    1) DO_TG=$((1-DO_TG)) ;;
                    2) DO_BASHUP=$((1-DO_BASHUP)) ;;
                    3) LOG_UPLOAD=$((1-LOG_UPLOAD)) ;;
                    4) break ;;
                    *) echo -e "${RED}Invalid option!${NC}" ;;
                esac
            done
            ;;
        6) # Exit
            echo -e "\n${GREEN}Exiting... Goodbye!${NC}"
            exit 0
            ;;
        *) echo -e "\n${RED}Invalid option! Please try again.${NC}" ;;
    esac
done