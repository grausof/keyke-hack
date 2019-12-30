#!/bin/sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/lib
./h264grabber -r HIGH | RRTSP_RES=0 RRTSP_PORT=554 ./rRTSPServer &