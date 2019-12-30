#!/bin/sh
./h264grabber HIGH | RRTSP_RES=0 RRTSP_PORT=554 ./rRTSPServer &