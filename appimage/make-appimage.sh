#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"

# Build and install from local PKGBUILD
# Skip integrity check since sha512sums change with each release
export SKIP_INTEGRITY_CHECK=1
make-aur-package

# Find system icon
ICON_PATH=$(find /usr/share/icons -name "preferences-desktop-locale" -type f 2>/dev/null | head -1)
if [ -z "$ICON_PATH" ]; then
  ICON_PATH=$(find /usr/share/icons -name "preferences-desktop-locale*" -type f 2>/dev/null | head -1)
fi

export ICON="${ICON_PATH:-preferences-desktop-locale}"
export DESKTOP=/usr/share/applications/xfce-aero-lang-changer.desktop

# Bundle binary, deps, desktop, and icon into AppDir
quick-sharun /usr/bin/xfce-aero-lang-changer

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test
quick-sharun --test ./dist/*.AppImage
