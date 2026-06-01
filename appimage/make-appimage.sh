#!/bin/sh

set -eu

# Install package through PKGBUILD
curr_dir="$(pwd)"
cd ./pkgbuild
make-aur-package
cd "$curr_dir"

# Add debloated packages
get-debloated-pkgs --add-common --prefer-nano

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON="https://raw.githubusercontent.com/madmaxms/iconpack-obsidian/4cccdd3f2a1ac20bc0beea31ffb7a2ccdc424842/Obsidian/apps/96/preferences-desktop-locale.svg"
export DESKTOP=/usr/share/applications/xfce-aero-lang-changer.desktop

# Bundle binary, deps, desktop, and icon into AppDir
quick-sharun /usr/bin/xfce-aero-lang-changer

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test
quick-sharun --test ./dist/*.AppImage
