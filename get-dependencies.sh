#!/bin/sh

set -eu

echo "Installing package dependencies..."
pacman -Syu --noconfirm \
  rustup \
  cmake \
  base-devel \
  libx11 libxext libxinerama libxcursor libxrender libxfixes libxft \
  fontconfig pango cairo glib2

rustup default stable

echo "Installing debloated packages..."
get-debloated-pkgs --add-common --prefer-nano
