# OnePlus guacamole (7T Pro 5G / HD1907) kernel rebuild for CONFIG_MODULE_SIG_FORCE=n

## Why
Enable loading of a **patched, unsigned** `qca_cld3_wlan.ko` (spectral null → real
redirects, see `../mod/patch_module.py`). Stock kernel has `CONFIG_MODULE_SIG_FORCE=y`
so the patch is rejected (`dmesg: "=out in signing params"` / `module_verify` ENOKEY path).

## Source pin
- Repo: `OnePlusOSS/android_kernel_oneplus_sm8150`, branch `oneplus/SM8150_Q_10.0`
- Commit: `92ce282d017e30a87ef21b3079ec02521f15bd2b` (2020-10-14, still 4.14.117)
  -> device kernel is `4.14.117-perf+` (Sep 15 2020). Not the exact ship commit
  (public tree is sanitized) but same Makefile VERSION level → vermagic matches.
- gzip-verified file = `kernel.raw` from device = **raw uncompressed Image** (not gz-dtb).

## Config changes vs device /proc/config.gz (`boot/device.config`)
- `CONFIG_MODULE_SIG_FORCE` = n   (only change to VERMAGIC-NEUTRAL flags)
- `CONFIG_LOCALVERSION` = "-perf+" (device is 4.14.117-**perf+**; without the "+" the
  module's vermagic `4.14.117-perf+` mismatches → load refused even with FORCE=n)
- everything else = device `device.config` (extracted via `zcat /proc/config.gz`)

Note: LOCALVERSION_AUTO was not set, so no `-g<hash>` contamination.

## Why the Kconfig-neutralizer (fix_kconfig.sh)
Public tree is **sanitized**: `drivers/input/oneplus_touchscreen/Kconfig` (and several
others) referenced by `device.config` are absent, so `make olddefconfig` fails. The script
comments out `source` lines pointing at missing files → those options become `n`. This is
expected/deliberate (device-specific dirs removed upstream, not needed for kernel Image).

## Artifact
- GitHub Actions run → `kernel/arch/arm64/boot/Image` (raw) → downloadable artifact.
- `Show vermagic` step cats `include/generated/utsrelease.h`.

## Flash (see flash_one_shot.sh)
1. adb push Image → /data/local/tmp/kernel.new
2. on device: dd boot_a → magiskboot unpack → swap kernel → repack → pull
3. fastboot flash boot (bootloader unlocked, vbstate=orange)
4. boot, verify: `uname -a` = 4.14.117-**perf+**, `cat /sys/module/wlan/parameters/con_mode_monitor` = 4
5. spectral tool: `su -c '/vendor/in/spectraltool -i wlan0'` (start via interactive `start`)

## Rollback
- Re-flash the saved `boot_backup_now.img` (fast boot) or set module+Magics disable.
- Kernel Image from stock: original `boot_a.img` (100MB).