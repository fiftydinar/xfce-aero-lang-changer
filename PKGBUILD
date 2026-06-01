# Maintainer: fiftydinar <srbaizoki4@tuta.io>

pkgname=xfce-aero-lang-changer
pkgver=1.0.5
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
sha512sums=('5af30d6c0e17f37f7ca24f4d83c2df2b3adbfa7101ea6ea68fb8563b9e315cd4001ca3103749f9032e425aa54cea4543e7320c3dc8d85d46894531498d1ddfa2')

build() {
  cd "$srcdir/$pkgname-$pkgver"
  make
}

package() {
  cd "$srcdir/$pkgname-$pkgver"
  make install PREFIX=/usr DESTDIR="$pkgdir"
}
