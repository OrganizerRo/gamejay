#!/bin/sh
set -eu

BOARD_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
ROM_IMAGE="$BINARIES_DIR/romdata.exfat"

rm -f "$ROM_IMAGE"
truncate -s 256M "$ROM_IMAGE"
"$HOST_DIR/sbin/mkfs.exfat" -L ROMDATA "$ROM_IMAGE"

rm -rf "$BUILD_DIR/genimage-efi.tmp"
"$HOST_DIR/bin/genimage" \
	--rootpath "$TARGET_DIR" \
	--tmppath "$BUILD_DIR/genimage-efi.tmp" \
	--inputpath "$BINARIES_DIR" \
	--outputpath "$BINARIES_DIR" \
	--config "$BOARD_DIR/genimage-efi.cfg"

rm -rf "$BUILD_DIR/genimage-bios.tmp"
"$HOST_DIR/bin/genimage" \
	--rootpath "$TARGET_DIR" \
	--tmppath "$BUILD_DIR/genimage-bios.tmp" \
	--inputpath "$BINARIES_DIR" \
	--outputpath "$BINARIES_DIR" \
	--config "$BOARD_DIR/genimage-bios.cfg"
