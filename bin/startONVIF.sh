#!/bin/sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/lib

./onvif_srvd --model KEYKE --manufacturer KEYKE --firmware_ver 0.1.7 --hardware_id UffX --serial_num XXX --ifs wlan0 --port 80 --scope onvif://www.onvif.org/Profile/S --name Profile_0 --width 640 --height 360 --url rtsp://%s/ch0_0.h264 --type H264