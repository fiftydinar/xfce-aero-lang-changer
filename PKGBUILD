# Maintainer: fiftydinar <srbaizoki4@tuta.io>

pkgname=xfce-aero-lang-changer
pkgver=1.0.5
pkgrel=1
pkgdesc="GUI language switcher for XFCE with Aero-style theming"
arch=('x86_64')
url="https://github.com/fiftydinar/xfce-aero-lang-changer"
license=('Apache-2.0')
depends=('fltk')
makedepends=('cargo' 'make' 'cmake')
source=("xfce-aero-lang-changer-$pkgver.tar.gz::https://github.com/fiftydinar/xfce-aero-lang-changer/archive/refs/tags/v$pkgver.tar.gz")
sha512sums=('56aeeb914bfc0f026c31ae26f9c0e4e09a46cadb394d2509afbfbb5fdf546500094d13a86e9b34f49faaea1d10e6c5914b0e5d6ba4bdca55a7c4ca749aaf2fb3')

build() {
  cd "$srcdir/$pkgname-$pkgver"
  make  
}

package() {
  cd "$srcdir/$pkgname-$pkgver"
  make install PREFIX=/usr DESTDIR="$pkgdir"
}
