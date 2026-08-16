# r67: force CONFIG_64BIT/SMP + unmask STAGE 1 (set -eo pipefail, V=1, autoconf dump)
p = r'C:\Users\HP\wlanre\build\.github\workflows\build.yml'
s = open(p, encoding='utf-8').read()

old = (
    '          ./scripts/config --disable CONFIG_MODULE_SIG_FORCE\n'
    '          ./scripts/config --disable CONFIG_GCC_WERROR\n'
    '          ./scripts/config --set-str CONFIG_LOCALVERSION "-perf+"\n'
    '          make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig\n'
    "          grep -E 'CONFIG_(THREAD_INFO_IN_TASK|ARM64_VA_BITS|ARM64_PAGE_SHIFT|64BIT)=' .config | head -5"
)
new = (
    '          ./scripts/config --disable CONFIG_MODULE_SIG_FORCE\n'
    '          ./scripts/config --disable CONFIG_GCC_WERROR\n'
    '          ./scripts/config --enable CONFIG_64BIT\n'
    '          ./scripts/config --enable CONFIG_SMP\n'
    '          ./scripts/config --set-str CONFIG_LOCALVERSION "-perf+"\n'
    '          make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig\n'
    "          grep -E 'CONFIG_(THREAD_INFO_IN_TASK|ARM64_VA_BITS|ARM64_PAGE_SHIFT|64BIT|SMP)=' .config | head -7\n"
    "          grep -E 'CONFIG_(64BIT|SMP)=' include/generated/autoconf.h 2>/dev/null | head -4"
)
assert old in s, 'PATTERN1 MISS'
s = s.replace(old, new)
print('config-enable applied')

old2 = (
    '          make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j1 prepare 2>&1 | tee -a /kernelsrc/build.log | tail -8'
)
new2 = (
    '          set -eo pipefail\n'
    '          make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- V=1 -j1 prepare 2>&1 | tee -a /kernelsrc/build.log\n'
    "          grep -E 'CONFIG_(64BIT|SMP)=' include/generated/autoconf.h | head -4"
)
if old2 in s:
    s = s.replace(old2, new2)
    print('stage1 unmasked')
else:
    print('PATTERN2 MISS')
    # find the prepare line context
    import re
    for m in re.finditer(r'prepare[^\n]*', s):
        print(repr(s[max(0,m.start()-80):m.end()+20]))

open(p, 'w', encoding='utf-8').write(s)
print('written')