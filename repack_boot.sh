#!/usr/bin/env bash
# Repack boot.img with a new raw ARM64 kernel Image, preserving Magisk ramdisk.
# Use when a GitHub Actions build artifact has been downloaded.
# PRE-FLIGHT (verify before flashing):
#   * phone bootloader unlocked (vbstate=orange)
#   * boot_current.img backed up (boot_a.img exists)
set -euo pipefail
cd "$(dirname "$0")/boot"

KERNEL_RAW="$1"   # path to the fresh arch/arm64/boot/Image (raw)
OUT="$2:-boot_forceoff.img"
WORK=repack_work

rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"

echo "== unpack boot_current.img =="
../magiskboot unpack ../boot_current.img
ls -la
# magiskboot hands out: kernel, ramdisk(.cpio)/initrd, dtb-something, header info

echo "== swap kernel =="
cp "$KERNEL_RAW" kernel

echo "== repack =="
../magiskboot repack ../boot_current.img "$OUT"
cd ..
mv "$WORK/$OUT" ./
echo "== verify =="
../magiskboot info "$OUT" | head -20
echo "DONE: $OUT"