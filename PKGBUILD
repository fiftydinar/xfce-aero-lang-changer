# Maintainer: fiftydinar <srbaizoki4@tuta.io>

pkgname=xfce-aero-lang-changer
pkgver=1.0.5
pkgrel=1
pkgdesc="GUI language switcher for XFCE with Aero-style theming"
arch=('x86_64')
url="https://github.com/fiftydinar/xfce-aero-lang-changer"
license=('Apache-2.0')

# Build option: set _link=static for static linking (bundled fltk)
#               set _link=dynamic for dynamic linking (system fltk)
# _link=static is the default here, because on Arch, fltk-git fails to build, and latest fltk is required, not the stable one
# _link=dynamic is the default in upstream repo
_link=${_link:-static}

# fltk-sys dynamically links against these regardless of bundling
_x11_libs=('libx11' 'libxext' 'libxinerama' 'libxcursor' 'libxrender' 'libxfixes' 'libxft')
_x11_deps=("${_x11_libs[@]}" 'fontconfig' 'pango' 'cairo' 'glib2')

if [ "$_link" = "static" ]; then
  depends=("${_x11_deps[@]}")
  makedepends=('cargo' 'make' 'cmake')
else
  depends=('fltk')
  makedepends=('cargo' 'make' 'cmake')
fi

source=("xfce-aero-lang-changer-$pkgver.tar.gz::https://github.com/fiftydinar/xfce-aero-lang-changer/archive/refs/tags/v$pkgver.tar.gz")
sha512sums=('ec51bf1012dd2174e4884ed15f8f30f9a7a48dcc80759132150413c1f981bc9c4d9532aff14aceeee9b18a11eab83757d043536fe409275ec4165ab517c6c554')

build() {
  cd "$srcdir/$pkgname-$pkgver"
  make LINK="$_link"
}

package() {
  cd "$srcdir/$pkgname-$pkgver"
  make LINK="$_link" install PREFIX=/usr DESTDIR="$pkgdir"
}
