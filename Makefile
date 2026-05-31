PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
APPDIR ?= $(DATADIR)/applications

TARGET ?= release
BINARY := target/$(TARGET)/xfce-aero-lang-changer

# Linking mode: static (bundled fltk) or dynamic (system fltk)
LINK ?= dynamic
CARGO_ARGS := --release

ifeq ($(LINK),dynamic)
  CARGO_ARGS += --no-default-features
  CARGO_ARGS += --features fltk/system-fltk
  CARGO_ARGS += --features fltk/system-libjpeg
  CARGO_ARGS += --features fltk/system-libpng
  CARGO_ARGS += --features fltk/system-zlib
  # Query system FLTK for all needed link flags (distro-agnostic)
  FLTK_RAW := $(shell fltk-config --ldstaticflags 2>/dev/null)
  FLTK_LIBS := $(shell echo '$(FLTK_RAW)' \
    | sed 's|/[^ ]*libfltk\.a[^ ]*||g' \
    | tr ' ' '\n' | grep '^-l' | sed 's/^-l/-l dylib=/' | tr '\n' ' ')
  FLTK_LDIRS := $(shell echo '$(FLTK_RAW)' \
    | tr ' ' '\n' | grep '^-L' | tr '\n' ' ')
else
  CARGO_ARGS += --features bundled
endif

.PHONY: all build install uninstall clean

all: build

build:
	@if [ ! -f build.rs ]; then \
	  printf '%s\n' 'fn main() {' \
	    '    if std::env::var("CARGO_CFG_TARGET_ENV").as_deref() == Ok("gnu") {' \
	    '        println!("cargo:rustc-link-arg=-fuse-ld=bfd");' \
	    '    }' \
	    '    let output = std::process::Command::new("fltk-config")' \
	    '        .args(["--use-images", "--ldstaticflags"])' \
	    '        .output();' \
	    '    let Ok(output) = output else { return };' \
	    '    let flags = String::from_utf8_lossy(&output.stdout);' \
	    '    let mut lib_dirs: Vec<&str> = Vec::new();' \
	    '    let mut libs: Vec<&str> = Vec::new();' \
	    '    for flag in flags.split_whitespace() {' \
	    '        if let Some(dir) = flag.strip_prefix("-L") {' \
	    '            lib_dirs.push(dir);' \
	    '            println!("cargo:rustc-link-search=native={}", dir);' \
	    '        } else if let Some(lib) = flag.strip_prefix("-l") {' \
	    '            libs.push(lib);' \
	    '        }' \
	    '    }' \
	    '    for lib in libs {' \
	    '        let is_static = lib_dirs.iter().any(|dir| {' \
	    '            let path = std::path::Path::new(dir).join(format!("lib{}.a", lib));' \
	    '            path.exists()' \
	    '        });' \
	    '        let kind = if is_static { "static" } else { "dylib" };' \
	    '        println!("cargo:rustc-link-lib={}={}", kind, lib);' \
	    '    }' \
	    '}' > build.rs; \
	fi
	$(if $(filter dynamic,$(LINK)),RUSTFLAGS="$(RUSTFLAGS) $(FLTK_LDIRS) $(FLTK_LIBS) -C link-arg=-fuse-ld=bfd" )cargo build $(CARGO_ARGS)

$(BINARY): build

install: $(BINARY)
	install -Dm755 $(BINARY) $(DESTDIR)$(BINDIR)/xfce-aero-lang-changer
	install -dm755 $(DESTDIR)$(APPDIR)
	while IFS= read -r line || [ -n "$$line" ]; do \
		case "$$line" in \
			Exec=*) echo "Exec=$(BINDIR)/xfce-aero-lang-changer" ;; \
			*) echo "$$line" ;; \
		esac; \
	done < xfce-aero-lang-changer.desktop > $(DESTDIR)$(APPDIR)/xfce-aero-lang-changer.desktop

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/xfce-aero-lang-changer
	rm -f $(DESTDIR)$(APPDIR)/xfce-aero-lang-changer.desktop

clean:
	cargo clean
