#!/bin/sh
export PATH=${PATH}:/opt/yi/arm-linux-gnueabihf-4.8.3-201404/bin

export TARGET=arm-linux-gnueabihf
export CROSS=arm-linux-gnueabihf
export BUILD=x86_64-pc-linux-gnu

export CROSSPREFIX=${CROSS}-

export STRIP=${CROSSPREFIX}strip
export CXX=${CROSSPREFIX}g++
export CC=${CROSSPREFIX}gcc
export LD=${CROSSPREFIX}ld
export AS=${CROSSPREFIX}as
export AR=${CROSSPREFIX}ar

cd live || exit 1

make clean
make || exit 1
cp ./rRTSPServer ../../../bin/ || exit 1

arm-linux-gnueabihf-strip ../../../bin/* || exit 1