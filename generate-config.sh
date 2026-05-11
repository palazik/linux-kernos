#!/usr/bin/env bash
# KernOS kernel config generator
# Run this to generate the config file from CachyOS' BORE kernel config
# Only needs to be run when updating the base config
# Usage: ./generate-config.sh

set -euo pipefail

echo "Fetching CachyOS BORE kernel config..."
curl -fL "https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos-bore/config" -o config

if ! grep -q '^CONFIG_' config; then
  echo "Downloaded config does not look like a kernel config" >&2
  exit 1
fi

echo "Done. Config saved to ./config"
echo "The PKGBUILD will apply KernOS tweaks on top via scripts/config"
