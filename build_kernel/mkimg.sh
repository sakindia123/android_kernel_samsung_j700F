#!/bin/bash

FIT=custom_defconfig
DTS=/home/sarthak/j7/kernel/arch/arm64/boot/dts
IMG=/home/sarthak/j7/kernel/arch/arm64/boot
BK=/home/sarthak/j7/kernel/build_kernel
OUT=/home/sarthak/j7/kernel/output
DT=j7.dtb

# Cleanup old files from build environment
echo -n "Cleanup build environment.........................."
rm -rf $BK/ramdisk.cpio.gz
rm -rf $BK/Image*
rm -rf $BK/boot*.img
rm -rf $BK/output/boot.img
rm -rf $IMG/Image
rm -rf $DTS/.*.tmp
rm -rf $DTS/.*.cmd
rm -rf $OUT/*.zip
rm -rf $OUT/*.tar
echo "Done"

# Set build environment variables
echo -n "Set build variables................................"
export ARCH=arm64
export SUBARCH=arm64
export USE_SEC_FIPS_MODE=true
export KCONFIG_NOTIMESTAMP=true
echo "Done"

echo -n "Build Kernel Image......................................."
make -j12
if [ -f "arch/arm64/boot/Image" ]; then
	echo "Done"
	# Copy the compiled image to the build_kernel directory
	mv $IMG/Image $BK/Image
else
	clear
	echo
	echo "Compilation failed on kernel !"
	echo
	while true; do
    		read -p "Do you want to run a Make command to check the error?  (y/n) > " yn
    		case $yn in
        		[Yy]* ) make; echo ; exit;;
        		[Nn]* ) echo; exit;;
        	 	* ) echo "Please answer yes or no.";;
    		esac
	done
fi

echo -n "Build dt.img......................................."

./tools/dtbtool -o $BK/dt.img -s 2048 -p ./scripts/dtc/ $DTS/ | sleep 1

# Calculate DTS size for all images and display on terminal output
du -k "$BK/dt.img" | cut -f1 >sizT
sizT=$(head -n 1 sizT)
rm -rf sizT
echo "$sizT Kb"

echo -n "Make Ramdisk archive..............................."
cd $BK/ramdisk
find .| cpio -o -H newc | lzma -9 > ../ramdisk.cpio.gz


echo -n "Make boot.img......................................"
cd ..
./mkbootimg --base 0x10000000 --kernel Image --ramdisk_offset 0x11000000 --tags_offset 0x10000100 --pagesize 2048 --ramdisk ramdisk.cpio.gz --dt dt.img -o boot.img
echo "Done"

echo -n "Creating flashable zip............................."
cp boot.img output/
cd output
zip -r twrp_kernel.zip boot.img system/xbin/busybox META-INF/com/google/android/update-binary META-INF/com/google/android/updater-script
mv twrp_kernel.zip ../
cd ../
echo "Done"

echo
cd ../
read -p "Do you want to Clean the source? (y/n) > " mc
if [ "$mc" = "Y" -o "$mc" = "y" ]; then
	make clean
fi

echo
echo "Build completed"
echo
