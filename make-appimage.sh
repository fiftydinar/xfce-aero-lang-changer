#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"

# Build the Rust binary
cargo build --release

# Find system icon
ICON_PATH=$(find /usr/share/icons -name "preferences-desktop-locale" -type f 2>/dev/null | head -1)
if [ -z "$ICON_PATH" ]; then
  ICON_PATH=$(find /usr/share/icons -name "preferences-desktop-locale*" -type f 2>/dev/null | head -1)
fi

export ICON="${ICON_PATH:-preferences-desktop-locale}"
export DESKTOP=./xfce-aero-lang-changer.desktop

# Bundle binary and deps into AppDir
quick-sharun target/release/xfce-aero-lang-changer

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test
quick-sharun --test ./dist/*.AppImage
