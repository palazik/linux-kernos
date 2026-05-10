# Maintainer: palazik <https://github.com/palazik>
# Based on CachyOS linux-cachyos-bore PKGBUILD

pkgbase=linux-kernos
pkgver=7.0.3  # bumped automatically by pkgver()
pkgrel=1
pkgdesc='KernOS optimized kernel - BORE + ThinLTO + CachyOS patches'
arch=(x86_64)
url='https://github.com/palazik/linux-kernos'
license=(GPL-2.0-only)
makedepends=(
  bc
  cpio
  curl
  gettext
  libelf
  pahole
  perl
  python
  tar
  xz
  zstd
  clang
  llvm
  lld
)
options=(!strip)

pkgver() {
  curl -s https://www.kernel.org/releases.json \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['latest_stable']['version'])"
}

# _major and _patchsource must be functions/deferred so they use the
# updated pkgver after pkgver() runs. makepkg re-sources the PKGBUILD
# with the new pkgver, so these top-level vars will be correct on the
# second pass when source[] is actually evaluated.
_major="${pkgver%.*}"
_patchsource="https://raw.githubusercontent.com/cachyos/kernel-patches/master/${_major}"

source=(
  "https://cdn.kernel.org/pub/linux/kernel/v${pkgver%%.*}.x/linux-${pkgver}.tar.xz"
  "bore-cachy.patch::${_patchsource}/sched/0001-bore-cachy.patch"
  "clang-polly.patch::${_patchsource}/misc/0001-clang-polly.patch"
  "acpi-call.patch::${_patchsource}/misc/0001-acpi-call.patch"
  "config"
)

sha256sums=(
  'SKIP'
  'SKIP'
  'SKIP'
  'SKIP'
  'SKIP'
)

prepare() {
  cd linux-${pkgver}

  echo "Applying BORE scheduler..."
  patch -Np1 < ../bore-cachy.patch

  echo "Applying Clang Polly optimizations..."
  patch -Np1 < ../clang-polly.patch

  echo "Applying ACPI call patch..."
  patch -Np1 < ../acpi-call.patch

  echo "Setting up KernOS config..."
  cp ../config .config

  # KernOS version string
  scripts/config --set-str LOCALVERSION "-kernos"

  # O3 optimization (matches CachyOS default)
  scripts/config -d CC_OPTIMIZE_FOR_PERFORMANCE \
                 -e CC_OPTIMIZE_FOR_PERFORMANCE_O3

  # ThinLTO with Clang
  scripts/config -e LTO_CLANG_THIN \
                 -d LTO_NONE \
                 -d LTO_CLANG_FULL

  # 1000Hz tick rate
  scripts/config -d HZ_300 -e HZ_1000 --set-val HZ 1000

  # Full tickless
  scripts/config -d HZ_PERIODIC -d NO_HZ_IDLE \
                 -d CONTEXT_TRACKING_FORCE \
                 -e NO_HZ_FULL_NODEF -e NO_HZ_FULL \
                 -e NO_HZ -e NO_HZ_COMMON -e CONTEXT_TRACKING

  # Full preemption
  scripts/config -e PREEMPT -d PREEMPT_LAZY

  # BORE scheduler
  scripts/config -e SCHED_BORE

  # sched-ext support
  scripts/config -e SCHED_CLASS_EXT

  # BBR TCP congestion control
  scripts/config -m TCP_CONG_CUBIC \
                 -d DEFAULT_CUBIC \
                 -e TCP_CONG_BBR \
                 -e DEFAULT_BBR \
                 --set-str DEFAULT_TCP_CONG bbr \
                 -m NET_SCH_FQ_CODEL \
                 -e NET_SCH_FQ \
                 -d CONFIG_DEFAULT_FQ_CODEL \
                 -e CONFIG_DEFAULT_FQ

  # zstd compression
  scripts/config -e KERNEL_ZSTD

  # Transparent hugepages - always
  scripts/config -d TRANSPARENT_HUGEPAGE_MADVISE \
                 -e TRANSPARENT_HUGEPAGE_ALWAYS

  # Disable debug bloat
  scripts/config -d DEBUG_INFO \
                 -d DEBUG_INFO_BTF \
                 -d SLUB_DEBUG \
                 -d PM_DEBUG \
                 -d FTRACE \
                 -d KPROBES

  make olddefconfig
}

build() {
  cd linux-${pkgver}

  make -j$(nproc) \
    CC=clang \
    LD=ld.lld \
    LLVM=1 \
    LLVM_IAS=1 \
    all
}

_package() {
  pkgdesc="KernOS optimized kernel"
  depends=(coreutils kmod initramfs)
  optdepends=(
    'wireless-regdb: to set the correct wireless channels of your country'
    'linux-firmware: firmware images needed for some devices'
    'scx-scheds: sched-ext schedulers'
  )
  provides=(VIRTUALBOX-GUEST-MODULES WIREGUARD-MODULE KSMBD-MODULE)

  cd linux-${pkgver}

  local kernver="$(<version)"
  local modulesdir="${pkgdir}/usr/lib/modules/${kernver}"

  mkdir -p "${modulesdir}"

  echo "Installing kernel image..."
  install -Dm644 "$(make -s image_name)" "${modulesdir}/vmlinuz"
  echo "linux-kernos" | install -Dm644 /dev/stdin "${modulesdir}/pkgbase"

  echo "Installing modules..."
  ZSTD_CLEVEL=19 make \
    INSTALL_MOD_PATH="${pkgdir}/usr" \
    INSTALL_MOD_STRIP=1 \
    DEPMOD=/doesnt/exist \
    modules_install

  rm "${modulesdir}/build"
}

_package-headers() {
  pkgdesc="KernOS optimized kernel headers"
  depends=(pahole)

  cd linux-${pkgver}
  local kernver="$(<version)"
  local builddir="${pkgdir}/usr/lib/modules/${kernver}/build"

  echo "Installing headers..."
  make INSTALL_HDR_PATH="${builddir}" headers_install
  install -Dm644 .config "${builddir}/.config"
}

pkgname=(
  linux-kernos
  linux-kernos-headers
)

for _p in "${pkgname[@]}"; do
  eval "package_${_p}() { _package${_p#linux-kernos}; }"
done
