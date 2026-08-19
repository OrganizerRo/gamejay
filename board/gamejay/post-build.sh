#!/bin/sh
set -eu

BOARD_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"

install -D -m 0644 "$BOARD_DIR/grub.cfg" \
	"$TARGET_DIR/boot/grub/grub.cfg"
install -D -m 0644 "$BOARD_DIR/grub.cfg" \
	"$BINARIES_DIR/efi-part/EFI/BOOT/grub.cfg"
install -D -m 0644 "$BINARIES_DIR/bzImage" \
	"$TARGET_DIR/boot/bzImage"

if [ -f "$TARGET_DIR/lib/grub/i386-pc/boot.img" ]; then
	install -m 0644 "$TARGET_DIR/lib/grub/i386-pc/boot.img" \
		"$BINARIES_DIR/boot.img"
fi
