#!/bin/sh
echo "--------------------------home app init.sh--------------------------"

	mount tmpfs /tmp -t tmpfs -o size=32m
	mkdir /tmp/sd

	mkdir /tmp/var
	mkdir /tmp/var/run

###mstar ko###
	insmod /home/ms/ko/mdrv_mmfe.ko
	insmod /home/ms/ko/mdrv_mvhe.ko
	insmod /home/ms/ko/mstar_jpe.ko
	echo 2 > /sys/class/mstar/mvhe/rct
	#echo 3 > /sys/class/mstar/mmfe/rct

### MMC ###
	insmod /home/base/ko/mmc_core.ko
	insmod /home/base/ko/mmc_block.ko

### VFAT ###
	insmod /home/base/ko/fat.ko
	insmod /home/base/ko/vfat.ko

### SDMMC ###
	insmod /home/base/ko/kdrv_sdmmc.ko
### sleep 1s is must for checkdisk
	sleep 1

	checkdisk
	rm -fr /tmp/sd/FSCK*.REC
	umount -l /tmp/sd
	mount -t vfat /dev/block/mmcblk0p1 /tmp/sd

	rm /etc/resolv.conf
	ln -s /tmp/resolv.conf /etc/resolv.conf

	insmod /home/base/ko/mdrv_cryptodev.ko
	insmod /home/base/ko/mdrv_crypto.ko

if [ -f /home/home_h305m ]; then
	echo "---/home/home_h305m exist, update begin---"
	dd if=/home/home_h305m of=/tmp/newver bs=24 count=1
	newver=$(cat /tmp/newver)
	if [ -f /home/homever ]; then
		curver=$(cat /home/homever)
	else
		curver=0
	fi
	echo check version: newver=$newver, curver=$curver
	if [ $newver != $curver ]; then
		### cipher ###
		sleep 1
		mkdir /tmp/update
		cp -rf /home/base/tools/extpkg.sh /tmp/update/extpkg.sh
		/tmp/update/extpkg.sh /home/home_h305m
		rm -rf /tmp/update
		rm -rf /home/home_h305m
		#sync
		echo "update finish"
		reboot -f
	fi
	echo "---same version ? update fail---"
	rm -rf mv /home/home_h305m
elif [ -f /tmp/sd/home_h305m ]; then
	echo "---tmp/sd/home_h305m exist, update begin---"
	dd if=/tmp/sd/home_h305m of=/tmp/newver bs=24 count=1
	newver=$(cat /tmp/newver)
	if [ -f /home/homever ]; then
		curver=$(cat /home/homever)
	else
		curver=0
	fi
	echo check version: newver=$newver, curver=$curver
	if [ $newver != $curver ]; then
		### cipher ###
		sleep 1
		mkdir /tmp/update
		cp -rf /home/base/tools/extpkg.sh /tmp/update/extpkg.sh
		/tmp/update/extpkg.sh /tmp/sd/home_h305m
		rm -rf /tmp/update
		mv /tmp/sd/home_h305m	/tmp/sd/home_h305m.done
		#sync
		echo "update finish"
		reboot -f
	fi
	echo "---same version ? update fail---"
	mv /tmp/sd/home_h305r	/tmp/sd/home_h305m.done
else
	echo "---update file(home_h305m) Not exist---"
fi

###do this after update
	sh /home/base/tools/xy_fixmem.sh

### USB_HOST,7601 need ###
	insmod /home/base/ko/usb-common.ko
	insmod /home/base/ko/usbcore.ko
	insmod /home/base/ko/ehci-hcd.ko force_host=1

### spi ###
	insmod /home/base/ko/spi-infinity.ko
echo "--------------------------insmod end--------------------------"

	echo 128 > /proc/sys/vm/lowmem_reserve_ratio
	echo 400 > /proc/sys/vm/vfs_cache_pressure
	echo 3 > /proc/sys/vm/drop_caches
	echo 2048 > /proc/sys/vm/min_free_kbytes

	sysctl -w vm.overcommit_memory=0
	sysctl -w vm.overcommit_ratio=50
	sysctl -w vm.min_free_kbytes=598
	sysctl -w vm.dirty_background_ratio=2
	sysctl -w vm.dirty_expire_centisecs=500
	sysctl -w vm.dirty_ratio=2
	sysctl -w vm.dirty_writeback_centisecs=100
	sysctl -w vm.admin_reserve_kbytes=0
	sysctl -w vm.user_reserve_kbytes=0

#	ifconfig eth0 up
#	num1=`expr $RANDOM % 100`
#	num2=`expr $RANDOM % 100`
#	num3=`expr $RANDOM % 100`
#	ifconfig eth0 hw ether 08:00:20:$num1:$num2:$num3
#	udhcpc -i eth0 &

	setprop mi.vi.src 2
	setprop mi.vi.img.sub 0
	setprop mi.sys.shrink_mem 1
	setprop mstar.omx.gop.disable 1
	setprop mi.osd.gop.use 0
	setprop mi.venc.bufcnt 1
	setprop mi.venc.sub.bufcnt 1
	setprop mi.vi.bufcnt 2
	setprop mi.vi.sub.bufcnt 2
	setprop mi.vi.sub.width 640
	setprop mi.vi.sub.height 360
	setprop mi.venc.stop.flush 1
	setprop mi.video.height.force.aligned32 1
	setprop omx.mainstream.min.resolution.width 1920
	setprop omx.mainstream.min.resolution.height 1088
	setprop mstar.omx.avqe.aecgain 10
	setprop mstar.omx.avqe.aecmode 13
	setprop mi.vi.yuvmon.pat /home/ms

	/home/app/script/factory_test.sh

	### wifi 7601 ###
	insmod /home/base/wifi/drv/cfg80211.ko
#	insmod /home/base/wifi/drv/mtprealloc.ko
#	insmod /home/base/wifi/drv/mt7601Usta.ko
	insmod /home/base/wifi/drv/8188fu.ko
	echo "MTK 7601" > /tmp/MTK

	sleep 1
	ifconfig wlan0 up
	ethmac=d2:`ifconfig wlan0 |grep HWaddr|cut -d' ' -f10|cut -d: -f2-`
	ifconfig eth0 hw ether $ethmac
	#CUSTOM MAC ETH0
	#ifconfig eth0 hw ether 08:00:00:00:00:01
	ifconfig eth0 up

	#echo "/tmp/sd/core.%e.%p" > /proc/sys/kernel/core_pattern

	cd /home/app
	ln -s oss oss_fast
	ln -s oss oss_lapse
	./log_server &
	./dispatch &

	if [ -f "/tmp/sd/Factory/factory_test.sh" ]; then
		/tmp/sd/Factory/config.sh
		exit
	fi

	sleep 2
	./rmm &
	sleep 2
	./mp4record &
	./cloud &
	./p2p_tnp &
	./oss &
	./oss_fast &
	./oss_lapse &
	./watch_process &
	#start telnet
	/home/app/localbin/busybox telnetd &
	#start ftp
	/home/app/localbin/busybox tcpsvd -vE 0.0.0.0 21 /home/app/localbin/busybox ftpd -w / &

	#Start RTSP and ONVIF on port 80
	#cd /home/app/localbin
	#./startRTSP.sh &
	#./startONVIF.sh &
	#cd /home/app
