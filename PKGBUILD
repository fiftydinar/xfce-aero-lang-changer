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
sha512sums=('c238f3117f7288993f48ebf31223dcc5a17ec4122eceee4262bcdac2a70c893efc2e429fcb3b29dc8ceaa6ced63e04bb7f97c21b9f94d6bcdf1e191421df0c77')

build() {
  cd "$srcdir/$pkgname-$pkgver"
  make  
}

package() {
  cd "$srcdir/$pkgname-$pkgver"
  make install PREFIX=/usr DESTDIR="$pkgdir"
}
