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
sha512sums=('275491f257db33f43b286682f37c617445f53327a3e2e6f4b335ad2db0c6e54e24526cae38286e041979c87df316df0dd77189da434954ec45ec8007ebc98165')

build() {
  cd "$srcdir/$pkgname-$pkgver"
  # Ensure build.rs exists — it queries fltk-config for the full set
  # of transitive link flags (Wayland, DBus, libdecor, etc.) that
  # Arch's system libfltk.a requires but the fltk-sys build script
  # does not emit on its own.
  printf '%s\n' 'fn main() {' \
    '    if let Ok(output) = std::process::Command::new("fltk-config")' \
    '        .args(["--use-images", "--ldstaticflags"])' \
    '        .output()' \
    '    {' \
    '        let flags = String::from_utf8_lossy(&output.stdout);' \
    '        for flag in flags.split_whitespace() {' \
    '            if let Some(lib) = flag.strip_prefix("-l") {' \
    '                println!("cargo:rustc-link-lib=dylib={}", lib);' \
    '            } else if let Some(dir) = flag.strip_prefix("-L") {' \
    '                println!("cargo:rustc-link-search=native={}", dir);' \
    '            }' \
    '        }' \
    '        println!("cargo:rustc-link-lib=static=fltk");' \
    '        println!("cargo:rustc-link-lib=static=fltk_images");' \
    '    }' \
    '}' > build.rs
  make LINK="$_link"
}

package() {
  cd "$srcdir/$pkgname-$pkgver"
  make LINK="$_link" install PREFIX=/usr DESTDIR="$pkgdir"
}
