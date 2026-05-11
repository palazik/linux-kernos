# Maintainer: palazik <https://github.com/palazik>
# Based on CachyOS linux-cachyos-bore PKGBUILD

pkgbase=linux
pkgver=7.0.5
pkgrel=1
pkgdesc='KernOS optimized kernel - BORE + ThinLTO + CachyOS patches'
arch=(x86_64)
url='https://github.com/CachyOS/linux-cachyos'
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
  rsync
  tar
  xz
  zstd
  clang
  llvm
  lld
)
options=(!strip)

# pkgver() fetches the latest stable CachyOS linux release tag
# (format: cachyos-X.Y.Z-N) and extracts X.Y.Z as pkgver.
# We intentionally track CachyOS releases, NOT kernel.org directly,
# because bore-cachy.patch is written against CachyOS's pre-patched tree.
pkgver() {
  curl -s "https://github.com/CachyOS/linux/releases" \
    | grep -o 'cachyos-[0-9][^"&<]*' \
    | grep -v '\-rc' \
    | sort -V \
    | tail -1 \
    | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+'
}

_tagrel=1
# NOTE: _major, _srcname, _patchsource are intentionally computed inside each
# function body so they reflect the pkgver resolved by pkgver() at build time.

source=(
  # CachyOS pre-patched kernel tree — bore-cachy.patch is written against this, not vanilla
  # _srcname is resolved via pkgver() before makepkg fetches sources
  "https://github.com/CachyOS/linux/releases/download/cachyos-${pkgver}-${_tagrel}/cachyos-${pkgver}-${_tagrel}.tar.gz"

  # CachyOS patches — use pkgver directly so URLs resolve after pkgver() runs
  "bore-cachy.patch::https://raw.githubusercontent.com/cachyos/kernel-patches/master/${pkgver%.*}/sched/0001-bore-cachy.patch"
  "clang-polly.patch::https://raw.githubusercontent.com/cachyos/kernel-patches/master/${pkgver%.*}/misc/0001-clang-polly.patch"
  "acpi-call.patch::https://raw.githubusercontent.com/cachyos/kernel-patches/master/${pkgver%.*}/misc/0001-acpi-call.patch"

  # KernOS config
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
  local _srcname="cachyos-${pkgver}-${_tagrel}"
  cd "${_srcname}"

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

  # O3 optimization
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

  # ArchISO live media support
  scripts/config -e BLOCK \
                 -e NET \
                 -e INET \
                 -e BLK_DEV_LOOP \
                 -m BLK_DEV_NBD \
                 -e MD \
                 -m BLK_DEV_DM \
                 -m DM_SNAPSHOT \
                 -m SCSI \
                 -m CDROM \
                 -m BLK_DEV_SR \
                 -m OVERLAY_FS \
                 -e SQUASHFS \
                 -e ISO9660_FS \
                 -m MTD \
                 -m MTD_PHRAM \
                 -m MTD_BLOCK \
                 -e NETWORK_FILESYSTEMS \
                 -m NFS_FS \
                 -e USB_SUPPORT \
                 -m USB \
                 -m HID \
                 -m USB_HID \
                 -m HID_GENERIC

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

  # Generate the version file used by _package() to determine the module dir
  make -s kernelrelease > version
}

build() {
  local _srcname="cachyos-${pkgver}-${_tagrel}"
  cd "${_srcname}"

  make -j$(nproc) \
    CC=clang \
    LD=ld.lld \
    LLVM=1 \
    LLVM_IAS=1 \
    all
}

_package() {
  pkgdesc="KernOS optimized kernel"
  install=linux.install
  depends=(coreutils kmod initramfs)
  optdepends=(
    'wireless-regdb: to set the correct wireless channels of your country'
    'linux-firmware: firmware images needed for some devices'
    'scx-scheds: sched-ext schedulers'
  )
  provides=(VIRTUALBOX-GUEST-MODULES WIREGUARD-MODULE KSMBD-MODULE)

  local _srcname="cachyos-${pkgver}-${_tagrel}"
  cd "${_srcname}"

  local kernver="$(<version)"
  local modulesdir="${pkgdir}/usr/lib/modules/${kernver}"

  mkdir -p "${modulesdir}"

  echo "Installing kernel image..."
  install -Dm644 "$(make -s image_name)" "${modulesdir}/vmlinuz"
  install -Dm644 "$(make -s image_name)" "${pkgdir}/boot/vmlinuz-${pkgbase}"
  echo "${pkgbase}" | install -Dm644 /dev/stdin "${modulesdir}/pkgbase"

  echo "Installing modules..."
  ZSTD_CLEVEL=19 make \
    INSTALL_MOD_PATH="${pkgdir}/usr" \
    INSTALL_MOD_STRIP=1 \
    DEPMOD=/doesnt/exist \
    modules_install

  rm -f "${modulesdir}/build"
}

_package-headers() {
  pkgdesc="KernOS optimized kernel headers"
  depends=(pahole)

  local _srcname="cachyos-${pkgver}-${_tagrel}"
  cd "${_srcname}"
  local kernver="$(<version)"
  local builddir="${pkgdir}/usr/lib/modules/${kernver}/build"

  echo "Installing headers..."
  make INSTALL_HDR_PATH="${builddir}" headers_install
  install -Dm644 .config "${builddir}/.config"
}

pkgname=(
  linux
  linux-headers
)

for _p in "${pkgname[@]}"; do
  eval "package_${_p}() { _package${_p#linux}; }"
done
