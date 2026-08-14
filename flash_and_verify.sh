#!/usr/bin/env bash
# Full spectral-enable sequence for the OnePlus 7T Pro 5G (HD1907).
# 1. push patched-nosig wlan module + conmon Magisk module to device
# 2. reboot into fastboot
# 3. fastboot flash boot <patched boot.img>
# 4. boot, verify module loaded + spectral callbacks active
set -euo pipefail
ADB="${ADB:-C:/Android/adb.exe}"
FASTBOOT="${FASTBOOT:-fastboot}"
BOOT_IMG="$1"     # path to fully-repacked boot image with FORCE=n kernel
KO_NOSIG="$2"     # path to qca_cld3_wlan.ko.*.nosig (patched-signed-stripped)
DEV="${DEV:-77aeb8a8}"

echo "== 1. push module =="
"$ADB" -s $DEV push "$KO_NOSIG" /data/local/tmp/ko.nosig
"$ADB" -s $DEV shell su -c 'mkdir -p /data/adb/modules/conmon'
"$ADB" -s $DEV shell su -c 'cp /data/local/tmp/ko.nosig /data/adb/modules/conmon/qca_cld3_wlan.ko'

echo "== 2. fresh fastboot =="
"$ADB" -s $DEV reboot bootloader
echo "waiting for fastboot..."
until "$FASTBOOT" devices | grep -q fastboot; do sleep 2; done

echo "== 3. flash boot =="
"$FASTBOOT" flash boot "$BOOT_IMG"

echo "== 4. boot =="
"$FASTBOOT" reboot
sleep 60

echo "== 5. verify =="
"$ADB" -s $DEV wait-for-device
echo "-- module params --"
"$ADB" -s $DEV shell su -c 'cat /sys/module/wlan/parameters/con_mode_monitor' || true
echo "-- wlan0 type --"
"$ADB" -s $DEV shell su -c 'iw dev wlan0 info | head -3' || true
echo "-- dmesg spectral --"
"$ADB" -s $DEV shell su -c 'dmesg | grep -i spectral | tail -20' || true
echo "-- load test (if not auto-loaded) --"
"$ADB" -s $DEV shell su -c 'lsmod | grep -i wlan' || true