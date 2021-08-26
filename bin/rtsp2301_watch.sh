#!/bin/sh
pidfile=/var/run/rtsp2301_watch.pid
while true
do
	while ! kill -0 $(cat $pidfile) >/dev/null 2>&1
	do
		echo "Restarting rtsp2301."
		rm $pidfile
		/home/app/localbin/rtsp2301 >& /dev/null &
		pid=$!
		echo "Started rtsp2301 with PID $pid."
		echo $pid > $pidfile
	done
	sleep 30
done