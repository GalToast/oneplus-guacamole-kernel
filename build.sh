#!/usr/bin/env bash
# Documents the exact build the GitHub Actions runner performs.
# Local runs require an aarch64-linux-gnu- cross toolchain + build deps.
set -e
SRC_COMMIT=1fc6703db23f   # "Synchronize codes for HD1907 Oxygen OS 10.0.10.HD63CB" (2020-06-16)
                          # closest commit to the device's 2020-09-15 build; matches HD1907.
git clone --filter=blob:none --branch oneplus/SM8150_Q_10.0 \
  https://github.com/OnePlusOSS/android_kernel_oneplus_sm8150.git kernel
( cd kernel && git checkout "$SRC_COMMIT" )
cp build.config kernel/.config
( cd kernel && ./scripts/config --disable CONFIG_MODULE_SIG_FORCE \
    && make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig \
    && make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KCFLAGS="-Wno-error" -j"$(nproc)" Image )
echo "OUTPUT: kernel/arch/arm64/boot/Image"
