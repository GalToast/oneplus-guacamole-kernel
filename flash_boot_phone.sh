#!/usr/bin/env bash
# Build a patched boot.img ON THE PHONE (magiskboot is ARM ELF; won't run on Windows).
# 1. push new raw Image kernel  2. extract current boot partition
# 3. magiskboot unpack 4. swap kernel 5. repack 6. pull result 7. fastboot flash
set -euo pipefail
ADB="${ADB:-C:/Users/HP/platnew/platform-tools/adb.exe}"
FASTBOOT="${FASTBOOT:-C:/Users/HP/platnew/platform-tools/fastboot.exe}"
DEV="${DEV:-77aeb8a8}"
KERNEL_IMAGE="$1"      # arch/arm64/boot/Image (raw) from the build artifact
OUT="boot_patched.img"

BOOTDEV_A="/dev/block/by-name/boot_a"   # verify with: ls /dev/block/by-name | grep boot

echo "== 1. push kernel + magiskboot =="
"$ADB" -s $DEV push "$KERNEL_IMAGE" /data/local/tmp/kernel.new
"$ADB" -s $DEV push magiskboot /data/local/tmp/magiskboot
"$ADB" -s $DEV shell su -c 'chmod 755 /data/local/tmp/magiskboot'

echo "== 2. dump current boot image =="
"$ADB" -s $DEV shell su -c "dd if=$BOOTDEV_A of=/data/local/tmp/boot.img bs=1M conv=fsync"
echo "== 3. unpack =="
"$ADB" -s $DEV shell su -c 'cd /data/local/tmp && rm -rf wrk && mkdir wrk && cd wrk && cp ../boot.img android_boot.img && ../magiskboot unpack android_boot.img'
"$ADB" -s $DEV shell su -c 'ls -la /data/local/tmp/wrk/'
echo "== 4. swap kernel =="
"$ADB" -s $DEV shell su -c 'cd /data/local/tmp/wrk && cp ../kernel.new kernel'
echo "== 5. repack =="
"$ADB" -s $DEV shell su -c 'cd /data/local/tmp/wrk && ../magiskboot repack android_boot.img new-boot.img'
"$ADB" -s $DEV shell su -c 'ls -la /data/local/tmp/wrk/new-boot.img'
echo "== 6. pull =="
"$ADB" -s $DEV pull /data/local/tmp/wrk/new-boot.img ./$OUT
"$ADB" -s $DEV shell su -c 'rm -rf /data/local/tmp/wrk'

echo "== 7. flash (bootloader unlocked) =="
"$ADB" -s $DEV reboot bootloader
until "$FASTBOOT" devices 2>/dev/null | grep -qi fastboot; do sleep 2; done
"$FASTBOOT" flash boot "$OUT"
"$FASTBOOT" reboot
echo "done. Waiting for device boot..."
"$ADB" -s $DEV wait-for-device
sleep 30
"$ADB" -s $DEV shell su -c 'uname -a'
"$ADB" -s $DEV shell su -c 'iw dev wlan0 info | grep -i type' || true