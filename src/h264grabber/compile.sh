#!/bin/sh
arm-linux-gnueabihf-gcc h264grabber.c -o ../../bin/h264grabber -static -s -fPIC -O2
arm-linux-gnueabihf-strip ../../bin/* || exit 1