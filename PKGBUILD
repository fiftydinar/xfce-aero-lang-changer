# Maintainer: fiftydinar <srbaizoki4@tuta.io>

pkgname=xfce-aero-lang-changer
pkgver=1.0.6
pkgrel=1
pkgdesc="GUI language switcher for XFCE with Aero-style theming"
arch=('x86_64')
url="https://github.com/fiftydinar/xfce-aero-lang-changer"
license=('Apache-2.0')

# fltk-sys dynamically links against these regardless of bundling
_x11_libs=('libx11' 'libxext' 'libxinerama' 'libxcursor' 'libxrender' 'libxfixes' 'libxft')
depends=("${_x11_libs[@]}" 'fontconfig' 'pango' 'cairo' 'glib2')
makedepends=('cargo' 'make' 'cmake')

source=("xfce-aero-lang-changer-$pkgver.tar.gz::https://github.com/fiftydinar/xfce-aero-lang-changer/archive/refs/tags/v$pkgver.tar.gz")
sha512sums=('2c05b82b53df8d61acc571ffddd72672ababb8b6f958b352863437ccb6e5d765f57c0e9bcb3784a4bf639d3349ee5ce2a02c926c31337f53d8c9c6c84bf302bf')

build() {
  cd "$srcdir/$pkgname-$pkgver"
  make
}

package() {
  cd "$srcdir/$pkgname-$pkgver"
  make install PREFIX=/usr DESTDIR="$pkgdir"
}
