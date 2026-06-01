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
ifeq ($(ARCH),x86_64)
	curl -L -o xfce-aero-lang-changer-x86_64.AppImage \
		https://github.com/fiftydinar/xfce-aero-lang-changer/releases/$(APPIMAGE_VERSION)/download/xfce-aero-lang-changer-x86_64.AppImage
	chmod +x xfce-aero-lang-changer-x86_64.AppImage
else ifeq ($(ARCH),aarch64)
	curl -L -o xfce-aero-lang-changer-aarch64.AppImage \
		https://github.com/fiftydinar/xfce-aero-lang-changer/releases/$(APPIMAGE_VERSION)/download/xfce-aero-lang-changer-aarch64.AppImage
	chmod +x xfce-aero-lang-changer-aarch64.AppImage
else
	@echo "Unsupported architecture: $(ARCH). Only x86_64 and aarch64 are available."
	@exit 1
endif

install-appimage: download-appimage
ifeq ($(ARCH),x86_64)
	install -Dm755 xfce-aero-lang-changer-x86_64.AppImage $(DESTDIR)$(BINDIR)/xfce-aero-lang-changer
else ifeq ($(ARCH),aarch64)
	install -Dm755 xfce-aero-lang-changer-aarch64.AppImage $(DESTDIR)$(BINDIR)/xfce-aero-lang-changer
endif
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
