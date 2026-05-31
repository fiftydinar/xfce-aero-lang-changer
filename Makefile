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
  
  # Detect if we need the GNU-specific linker workaround
  # We check if 'rustc --print cfg' contains 'target_env="gnu"'
  IS_GNU := $(shell rustc --print cfg 2>/dev/null | grep -q 'target_env="gnu"' && echo 1)
  
  ifeq ($(IS_GNU),1)
    # Use gcc as linker to bypass Rust's default LLD wrapper on glibc
    RUSTFLAGS += -C linker=gcc -C link-arg=-fuse-ld=bfd
  endif
else
  CARGO_ARGS += --features bundled
endif

.PHONY: all build install uninstall clean

all: build

build:
	RUSTFLAGS="$(RUSTFLAGS) $(FLTK_LDIRS) $(FLTK_LIBS)" cargo build $(CARGO_ARGS)

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
