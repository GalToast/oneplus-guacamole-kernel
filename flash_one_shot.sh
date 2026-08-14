#!/usr/bin/env bash
# ONE-SHOT: flash the freshly built kernel Image (FORCE=n) to the phone and
# verify. Expects the GHA artifact already downloaded to ./artifact2/Image.
set -euo pipefail
cd "$(dirname "$0")"

ADB="C:/Users/HP/platnew/platform-tools/adb.exe"
FASTBOOT="C:/Users/HP/platnew/platform-tools/fastboot.exe"
DEV="77aeb8a8"
IMG="artifact2/Image"

echo "== [0] sanity: Image magic + size =="
head -c 8 "$IMG" | xxd | head -1
stat -c '%s bytes' "$IMG"

echo "== [1] push kernel to phone =="
MSYS_NO_PATHCONV=1 "$ADB" -s $DEV push "$IMG" /data/local/tmp/kernel.new

echo "== [2] dump CURRENT boot_a =="
MSYS_NO_PATHCONV=1 "$ADB" -s $DEV shell "su -c 'mkdir -p /data/local/tmp/bootwork && cd /data/local/tmp/bootwork && dd if=/dev/block/by-name/boot_a of=android_boot.img bs=1M conv=fsync 2>/dev/null && /data/local/tmp/magiskboot unpack android_boot.img >/dev/null 2>&1 && cp /data/local/tmp/kernel.new kernel && /data/local/tmp/magiskboot repack android_boot.img new-boot.img >/dev/null 2>&1 && md5sum android_boot.img new-boot.img && ls -la new-boot.img'"

echo "== [3] pull repacked =="
MSYS_NO_PATHCONV=1 "$ADB" -s $DEV pull /data/local/tmp/bootwork/new-boot.img ./boot_patched.img

echo "== [4] fastboot flash (unlocked verified) =="
MSYS_NO_PATHCONV=1 "$ADB" -s $DEV reboot bootloader
sleep 3
"$FASTBOOT" devices
"$FASTBOOT" flash boot ./boot_patched.img
"$FASTBOOT" reboot

echo "== [5] wait for boot + verify =="
"$ADB" wait-for-device 2>/dev/null || true
sleep 45
MSYS_NO_PATHCONV=1 "$ADB" -s $DEV shell "su -c 'uname -a; iw dev wlan0 info 2>/dev/null | head -3; cat /sys/module/wlan/parameters/con_mode_monitor 2>/dev/null; dmesg | grep -iE \"spectral|null_\" | tail -10'"