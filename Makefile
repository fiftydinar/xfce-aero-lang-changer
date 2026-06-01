PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
APPDIR ?= $(DATADIR)/applications
ARCH := $(shell uname -m)
APPIMAGE_VERSION ?= latest

.PHONY: all build install uninstall clean download-appimage install-appimage

all: build

build:
	cargo build --release

install: build
	install -Dm755 target/release/xfce-aero-lang-changer $(DESTDIR)$(BINDIR)/xfce-aero-lang-changer
	install -dm755 $(DESTDIR)$(APPDIR)
	while IFS= read -r line || [ -n "$$line" ]; do \
		case "$$line" in \
			Exec=*) echo "Exec=$(BINDIR)/xfce-aero-lang-changer" ;; \
			*) echo "$$line" ;; \
		esac; \
	done < xfce-aero-lang-changer.desktop > $(DESTDIR)$(APPDIR)/xfce-aero-lang-changer.desktop

download-appimage:
	@if [ "$(ARCH)" != x86_64 ] && [ "$(ARCH)" != aarch64 ]; then \
		echo "Unsupported architecture: $(ARCH). Only x86_64 and aarch64 are available."; \
		exit 1; \
	fi
	curl -L -o xfce-aero-lang-changer-$(ARCH).AppImage \
		https://github.com/fiftydinar/xfce-aero-lang-changer/releases/$(APPIMAGE_VERSION)/download/xfce-aero-lang-changer-$(ARCH).AppImage
	chmod +x xfce-aero-lang-changer-$(ARCH).AppImage

install-appimage: download-appimage
	install -Dm755 xfce-aero-lang-changer-$(ARCH).AppImage $(DESTDIR)$(BINDIR)/xfce-aero-lang-changer
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
