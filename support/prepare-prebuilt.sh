#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
output_dir="${1:-$repo_dir/output}"
release_base="${GAMEJAY_RELEASE_BASE:-https://github.com/OrganizerRo/gamejay/releases/download}"

base_id="$("$repo_dir/support/gamejay-dependency-id.sh" base)"
kernel_id="$("$repo_dir/support/gamejay-dependency-id.sh" kernel)"
cores_id="$("$repo_dir/support/gamejay-dependency-id.sh" cores)"
base_tag="gamejay-base-2025.02.10-$base_id"
kernel_tag="gamejay-kernel-2025.02.10-$kernel_id"
cores_tag="gamejay-cores-2025.02.10-$cores_id"

prebuilt_dir="$repo_dir/.prebuilt"
base_download_dir="$prebuilt_dir/base-download"
base_dir="$prebuilt_dir/base"
kernel_dir="$prebuilt_dir/kernel"
cores_download_dir="$prebuilt_dir/cores-download"
cores_dir="$prebuilt_dir/cores"
rm -rf \
	"$base_download_dir" "$base_dir" "$kernel_dir" \
	"$cores_download_dir" "$cores_dir"
mkdir -p \
	"$base_download_dir" "$base_dir" "$kernel_dir" \
	"$cores_download_dir" "$cores_dir" "$output_dir/images"

download() {
	local tag="$1"
	local file="$2"
	local destination="$3"
	wget -q -O "$destination" "$release_base/$tag/$file"
}

download "$base_tag" gamejay-base.tar.xz \
	"$base_download_dir/gamejay-base.tar.xz"
download "$base_tag" SHA256SUMS "$base_download_dir/SHA256SUMS"
(
	cd "$base_download_dir"
	sha256sum -c SHA256SUMS
	tar -xf gamejay-base.tar.xz -C "$base_dir"
)

download "$kernel_tag" bzImage "$kernel_dir/bzImage"
download "$kernel_tag" SHA256SUMS "$kernel_dir/SHA256SUMS"
(
	cd "$kernel_dir"
	sha256sum -c SHA256SUMS
)
cp "$kernel_dir/bzImage" "$output_dir/images/bzImage"

download "$cores_tag" gamejay-cores.tar.xz \
	"$cores_download_dir/gamejay-cores.tar.xz"
download "$cores_tag" SHA256SUMS "$cores_download_dir/SHA256SUMS"
(
	cd "$cores_download_dir"
	sha256sum -c SHA256SUMS
	tar -xf gamejay-cores.tar.xz
)
cp "$cores_download_dir"/cores/*_libretro.so "$cores_dir/"

printf 'Prepared base %s, kernel %s, and cores %s\n' \
	"$base_tag" "$kernel_tag" "$cores_tag"
