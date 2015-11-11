#!/bin/bash

FIT=custom_defconfig
DTS=/home/sarthak/j7/test/arch/arm64/boot/dts
IMG=/home/sarthak/j7/test/arch/arm64/boot
BK=/home/sarthak/j7/test/build_kernel
OUT=/home/sarthak/j7/test/output
DT=j7.dtb

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

