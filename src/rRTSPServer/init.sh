#!/bin/sh
ARCHIVE=live.2019.11.22.tar.gz
rm -rf ./live

if [ ! -f $ARCHIVE ]; then
    wget https://download.videolan.org/pub/contrib/live555/$ARCHIVE
fi
tar zxvf $ARCHIVE
patch -p0 < rRTSPServer.patch
cd live || exit 1

./genMakefiles linux-cross
cp -f ../Makefile.rRTSPServer Makefile