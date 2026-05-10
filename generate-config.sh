#!/usr/bin/env bash
# KernOS kernel config generator
# Run this to generate the config file from Arch's current config
# Only needs to be run when updating the base config
# Usage: ./generate-config.sh

set -euo pipefail

echo "Fetching Arch Linux kernel config..."
curl -sL "https://gitlab.archlinux.org/archlinux/packaging/packages/linux/-/raw/main/config" -o config

echo "Done. Config saved to ./config"
echo "The PKGBUILD will apply KernOS tweaks on top via scripts/config"
