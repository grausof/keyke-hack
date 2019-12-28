#!/bin/sh
if [ ! -f "/home/app/localbin/busybox" ]; then
  /home/app/script/killapp.sh
  cp /tmp/sd/test/app/busybox /home/app/localbin/busybox
  chmod +x /home/app/localbin/busybox
  cp /home/app/init.sh /tmp/sd/init.sh.bck
  mv /home/app/init.sh /home/app/init_old.sh
  cp /tmp/sd/test/init.sh /home/app/init.sh
  chmod +x /home/app/init.sh
  sync
  reboot
else
  log "[good] busybox is in the system."
fi