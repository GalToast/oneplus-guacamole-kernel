#!/usr/bin/env bash
# Post-flash verification: wants to answer in ONE round —
#   1. is the new kernel running? (uname)
#   2. did conmon's patched module load with con_mode_monitor=4?
#   3. if not: WHY? (vermagic mismatch / CRC / else) — dmesg tells all three.
ADB="${ADB:-C:/Users/HP/platnew/platform-tools/adb.exe}"
DEV="${DEV:-77aeb8a8}"
A(){ MSYS_NO_PATHCONV=1 "$ADB" -s $DEV shell su -c "$1"; }

echo "############ [1] KERNEL ############"
A 'uname -a'
A 'cat /proc/version'
echo "############ [2] MODULE STATE ############"
A 'lsmod | grep -i wlan || echo "wlan NOT loaded"'
A 'cat /sys/module/wlan/parameters/con_mode_monitor 2>/dev/null || echo "(no wlan param file)"'
A 'iw dev wlan0 info 2>/dev/null | head -6 || echo "wlan0 absent"'
echo "############ [3] WHY-OR-WORKED ############"
A 'dmesg | grep -iE "vermagic|module_layout|disagrees|signature|load_module|insmod|Unknown symbol|structural problem" | tail -15'
A 'dmesg | grep -iE "wlan|spectral" | tail -25'
echo "############ [4] SPECTRAL QUICK PROBE ############"
A 'dmesg -c >/dev/null; (printf "config,FFT_SIZE=256,SCAN_COUNT=1,SCAN_PERIOD=100\nstart\n" | timeout 10 /vendor/bin/spectraltool -i wlan0 >/data/local/tmp/sps.out 2>&1 &); sleep 11; echo ---TOOL---; cat /data/local/tmp/sps.out 2>/dev/null; echo ---DMESG---; dmesg | grep -iE "spectral|null_|scan|phyerr|report|fft" | tail -25'
echo "## marker strings to grep: 'Spectral scan start failed' / 'failed to send WLAN_NL_MSG_SPECTRAL_SCAN' / 'not enough buffers'"