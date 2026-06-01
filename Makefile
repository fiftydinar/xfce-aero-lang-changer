PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
APPDIR ?= $(DATADIR)/applications

.PHONY: all build install uninstall clean

all: build

build:
	cargo build --release

install: build
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
