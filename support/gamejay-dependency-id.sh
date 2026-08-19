#!/usr/bin/env bash
set -euo pipefail

mode="${1:?usage: gamejay-dependency-id.sh <base|kernel|cores|image>}"
repo_dir="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$repo_dir"

case "$mode" in
	base)
		files=(
			configs/gamejay_base_x86_64_defconfig
			support/gamejay-dependency-id.sh
		)
		;;
	kernel)
		files=(
			board/gamejay/linux-fragment.config
			configs/gamejay_kernel_x86_64_defconfig
			support/gamejay-dependency-id.sh
		)
		;;
	cores)
		mapfile -d '' files < <(
			find package -path 'package/libretro-*/*' -type f -print0 |
				LC_ALL=C sort -z
		)
		files+=(
			configs/gamejay_cores_x86_64_defconfig
			support/gamejay-dependency-id.sh
		)
		;;
	image)
		mapfile -d '' files < <(
			find package -type f \
				\( -name '*.mk' -o -name '*.hash' -o -name 'Config.in' \) \
				-print0 | LC_ALL=C sort -z
		)
		files+=(
			configs/gamejay_x86_64_defconfig
			package/gamejay-menu/gamejay-menu.mk
			package/retroarch/retroarch.mk
			support/gamejay-dependency-id.sh
		)
		;;
	*)
		echo "unknown dependency type: $mode" >&2
		exit 2
		;;
esac

{
	printf 'buildroot-2025.02.10\0'
	for file in "${files[@]}"; do
		printf '%s\0' "$file"
		cat "$file"
	done
} | sha256sum | cut -c1-16
