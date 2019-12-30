#!/bin/sh
./h264grabber HIGH | RRTSP_RES=0 RRTSP_PORT=554 ./rRTSPServer 
./h264grabber LOW | RRTSP_RES=1 RRTSP_PORT=554 ./rRTSPServer 