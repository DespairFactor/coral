#!/bin/bash
rm .version
# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
export CLANG_PATH=~/android/clang/clang-r416183d/bin
export PATH=${CLANG_PATH}:${PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=~/android/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=${HOME}/android/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export LD_LIBRARY_PATH=${HOME}/android/clang/clang-r416183d/lib64:$LD_LIBRARY_PATH
export LD=ld.lld
DEFCONFIG="floral_defconfig"

# Kernel Details
VER=".V1R"

# Paths
KERNEL_DIR=`pwd`
REPACK_DIR="${HOME}/android/AnyKernel3"
ZIP_MOVE="${HOME}/android/releases"
ZIMAGE_DIR="${HOME}/android/coral/out/arch/arm64/boot"

# Functions
function clean_all {
		rm -rf out
		git reset --hard > /dev/null 2>&1
		git clean -f -d > /dev/null 2>&1
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		rm -rf ~/android/AnyKernel3/dtbo.img
		rm -rf ~/android/AnyKernel3/Image.lz4
        rm -rf ~/android/AnyKernel3/Image.lz4-dtb
		make O=out CC=clang $DEFCONFIG
		make LD=ld.lld O=out CC=clang -j10 

}

function move_images {
		cp -vr $ZIMAGE_DIR/Image.lz4-dtb $REPACK_DIR/Image.lz4
        cp -vr out/arch/arm64/boot/dts/google/qcom-base/sm8150-v2.dtb $REPACK_DIR/dtb
}

function make_boot {
		python2 ./scripts/mkbootimg/mkbootimg.py --kernel $ZIMAGE_DIR/Image.lz4 --ramdisk scripts/prebuilt/ramdisk --dtb out/arch/arm64/boot/dts/google/qcom-base/sm8150-v2.dtb --cmdline 'console=ttyMSM0,115200n8 androidboot.console=ttyMSM0 printk.devkmsg=on msm_rtb.filter=0x237 ehci-hcd.park=3 service_locator.enable=1 androidboot.memcg=1 cgroup.memory=nokmem usbcore.autosuspend=7 androidboot.usbcontroller=a600000.dwc3 swiotlb=2048 androidboot.boot_devices=soc/1d84000.ufshc buildvariant=user' --header_version 2 -o $ZIP_MOVE/${KERNEL_VER}.img
}

function make_zip {
		cd $REPACK_DIR
		zip -r9 `echo $KERNEL_VER`.zip *
		mv  `echo $KERNEL_VER`.zip $ZIP_MOVE
		cd $KERNEL_DIR
}


DATE_START=$(date +"%s")


echo -e "${green}"
echo "-----------------"
echo "Making Kernel:"
echo "-----------------"
echo -e "${restore}"


# Vars
BASE_VER="Despair"
KERNEL_VER="$BASE_VER$VER"
export LOCALVERSION=~`echo $KERNEL_VER`
export LOCALVERSION=~`echo $KERNEL_VER`
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=DespairFactor
export KBUILD_BUILD_HOST=DarkRoom

echo

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build?" dchoice
do
case "$dchoice" in
	y|Y )
		make_kernel
		move_images
		make_boot
		make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done


echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo



