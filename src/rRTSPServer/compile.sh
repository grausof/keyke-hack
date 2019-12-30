#!/bin/sh
cd live || exit 1

make clean
make || exit 1
cp ./rRTSPServer ../../bin/ || exit 1

arm-linux-gnueabihf-strip ../../bin/* || exit 1