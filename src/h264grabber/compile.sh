#!/bin/sh
make clean
make || exit 1
cp ./h264grabber ../../bin/