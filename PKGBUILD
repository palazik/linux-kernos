# Maintainer: palazik <https://github.com/palazik>
# Contributor: Peter Jung ptr1337 <admin@cachyos.org>
# Based on Arch Linux linux PKGBUILD

pkgbase=linux-kernos
pkgver=7.0.3  # updated automatically by pkgver()
pkgrel=1
pkgdesc='KernOS optimized kernel - BORE + ThinLTO + CachyOS patches'
arch=(x86_64)
url='https://github.com/archlinux/linux'
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

# NOTE: these are evaluated after makepkg re-sources with the updated pkgver
_cachy_patch_ver="${pkgver%.*}"
_srctag="v${pkgver}-arch1"

source=(
  # Kernel tarball from kernel.org
  "https://cdn.kernel.org/pub/linux/kernel/v${pkgver%%.*}.x/linux-${pkgver}.tar.xz"
  "https://cdn.kernel.org/pub/linux/kernel/v${pkgver%%.*}.x/linux-${pkgver}.tar.sign"

  # Arch Linux kernel patch from GitHub releases
  "linux-${_srctag}.patch.zst::${url}/releases/download/${_srctag}/linux-${_srctag}.patch.zst"
  "linux-${_srctag}.patch.zst.sig::${url}/releases/download/${_srctag}/linux-${_srctag}.patch.zst.sig"

  # CachyOS patches
  "bore-cachy.patch::https://raw.githubusercontent.com/CachyOS/kernel-patches/master/${_cachy_patch_ver}/sched/0001-bore-cachy.patch"
  "clang-polly.patch::https://raw.githubusercontent.com/CachyOS/kernel-patches/master/${_cachy_patch_ver}/misc/0001-clang-polly.patch"
  "acpi-call.patch::https://raw.githubusercontent.com/CachyOS/kernel-patches/master/${_cachy_patch_ver}/misc/0001-acpi-call.patch"

  # KernOS config
  "config"
)

validpgpkeys=(
  ABAF11C65A2970B130ABE3C479BE3E4300411886  # Linus Torvalds
  647F28654894E3BD457199BE38DBBDC86092693E  # Greg Kroah-Hartman
  83BC8889351B5DEBBB68416EB8AC08600F108CDF  # Jan Alexander Steffens (heftig)
)

sha256sums=(
  'SKIP'  # kernel tarball
  'SKIP'  # kernel tarball sig
  'SKIP'  # arch patch
  'SKIP'  # arch patch sig
  'SKIP'  # bore-cachy
  'SKIP'  # clang-polly
  'SKIP'  # acpi-call
  'SKIP'  # config
)

prepare() {
  cd linux-${pkgver}

  echo "Applying Arch Linux patch..."
  # Use -f to follow symlinks that makepkg creates for renamed sources (:: syntax)
  zstd -d -f "../linux-${_srctag}.patch.zst" -o "../linux-${_srctag}.patch"
  patch -Np1 < "../linux-${_srctag}.patch"

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

  # O2 optimization
  scripts/config -e CC_OPTIMIZE_FOR_PERFORMANCE
  scripts/config -d CC_OPTIMIZE_FOR_SIZE

  # ThinLTO with Clang
  scripts/config -e LTO_CLANG_THIN
  scripts/config -d LTO_NONE
  scripts/config -d LTO_CLANG_FULL

  # 1000Hz tick rate
  scripts/config -d HZ_300
  scripts/config -e HZ_1000
  scripts/config --set-val HZ 1000

  # Full preemption
  scripts/config -e PREEMPT
  scripts/config -d PREEMPT_VOLUNTARY
  scripts/config -d PREEMPT_NONE

  # BBR3 TCP
  scripts/config -e TCP_CONG_BBR
  scripts/config -e NET_SCH_FQ
  scripts/config --set-str DEFAULT_TCP_CONG bbr

  # zstd compression
  scripts/config -e KERNEL_ZSTD

  # Transparent hugepages
  scripts/config -e TRANSPARENT_HUGEPAGE
  scripts/config -e TRANSPARENT_HUGEPAGE_ALWAYS
  scripts/config -d TRANSPARENT_HUGEPAGE_MADVISE

  # sched-ext support
  scripts/config -e SCHED_CLASS_EXT

  # Disable debug bloat
  scripts/config -d DEBUG_INFO
  scripts/config -d DEBUG_INFO_BTF
  scripts/config -d SLUB_DEBUG
  scripts/config -d PM_DEBUG
  scripts/config -d FTRACE
  scripts/config -d KPROBES

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
  make INSTALL_MOD_PATH="${pkgdir}/usr" \
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
