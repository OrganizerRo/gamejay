# GameJay OS

GameJay is a minimal x86_64 Linux gaming appliance built with Buildroot. It
boots directly into a controller-first SDL2 launcher, scans ROMs from a
Windows-compatible exFAT partition, and starts the selected game through
RetroArch. It is designed for low-spec Intel or AMD PCs with USB gamepads,
audio, and DRM/KMS graphics, as described in `_working/design_docV3.txt`.

The project intentionally has no desktop, display manager, systemd, package
manager, login prompt, or network service. BusyBox init starts the launcher on
the first console, and restarts it if it exits.

## Included systems

| System                            | Libretro core  | ROM directory |
| --------------------------------- | -------------- | ------------- |
| Super Nintendo                    | Snes9x 2010    | `snes`        |
| Nintendo Entertainment System     | FCEUmm         | `nes`         |
| Sega Genesis, Mega Drive, and 32X | PicoDrive      | `genesis`     |
| Arcade                            | MAME 2003-Plus | `arcade`      |
| PlayStation                       | PCSX-ReARMed   | `ps1`         |

All runtime components are included in the image. ROMs and proprietary BIOS
files are not included.

## Architecture

```text
Firmware (UEFI or BIOS)
  -> GRUB 2
  -> Linux 6.12
  -> read-only ext4 Buildroot root filesystem
  -> BusyBox init and eudev
  -> ROMDATA exFAT mount
  -> SDL2 GameJay launcher on DRM/KMS
  -> RetroArch and selected libretro core
```

Key runtime choices:

- **Graphics:** SDL2 and RetroArch render directly through DRM/KMS and Mesa;
  X11 and Wayland are not installed.
- **Audio:** ALSA is used directly; PulseAudio and PipeWire are not installed.
- **Controllers:** eudev, evdev, SDL game-controller support, and kernel HID
  drivers support multiple hot-pluggable USB gamepads.
- **Storage:** the OS partition is read-only. ROMs, BIOS files, saves, states,
  and generated configuration live on the writable `ROMDATA` partition.
- **Boot:** quiet GRUB and kernel settings minimize visible boot output and
  service overhead.

The design document also explores first-boot setup and MPV video backgrounds.
Those are deliberately not enabled in the current image: direct launch is
faster, smaller, and avoids two applications competing for DRM ownership.

## Repository layout

| Path                                                   | Purpose                                            |
| ------------------------------------------------------ | -------------------------------------------------- |
| `.github/workflows/Build-gamejay-img.yml`              | Reproducible GitHub image build                    |
| `BUILD_OPTIMIZATIONS.md`                               | Technical build acceleration guide                 |
| `configs/gamejay_x86_64_defconfig`                     | Complete Buildroot configuration                   |
| `configs/gamejay_{base,kernel,cores}_x86_64_defconfig` | Reusable dependency builds                         |
| `board/gamejay/`                                       | Kernel fragment, GRUB config, and image generation |
| `package/gamejay-menu/`                                | SDL2 launcher source and Buildroot package         |
| `package/retroarch/`                                   | Pinned RetroArch frontend package                  |
| `package/libretro-*/`                                  | Pinned emulator core packages                      |
| `package/gamejay-prebuilt-{base,cores}/`               | Verified dependency-bundle installers              |
| `rootfs-overlay/`                                      | Init, mount, launcher, and RetroArch runtime files |
| `support/`                                             | Dependency identity and local download helpers     |
| `Config.in`, `external.mk`, `external.desc`            | Buildroot external-tree entry points               |

Buildroot itself is downloaded at build time and is not vendored.

## Build with GitHub Actions

1. Push the repository to GitHub.
2. Open **Actions**.
3. Select **Build GameJay images**.
4. Select **Run workflow**.
5. Open the release linked in the workflow summary and download the combined
   ZIP or an individual image. The run also retains `gamejay-images` as a
   GitHub Actions artifact.

The workflow is also triggered by changes pushed to `master`. It pins
Buildroot `2025.02.10` and Bootlin's stable 2024.05-1 x86-64 glibc toolchain.
Four jobs prepare a content-addressed ABI-matched userspace base, Linux kernel,
five-core bundle, and final OS image. The three dependency jobs run in parallel
and compile only when their pinned source or configuration changes. Unchanged
image builds download checksum-verified binaries from GameJay prereleases.

The image job adds the GameJay menu and RetroArch to the verified target and
staging base, creates both disk layouts, verifies the output, and creates a
GitHub Release containing:

- `gamejay-images.zip` - both compressed images and their checksums.
- `gamejay.img.xz` - GPT image for 64-bit UEFI systems.
- `gamejay-bios.img.xz` - MBR image for legacy BIOS systems.
- `SHA256SUMS` - SHA-256 checksums of the compressed image downloads.

The release page links to every individual file as well as the combined ZIP.
Release tags use `gamejay-<workflow-run>.<attempt>-<short-commit>`, so reruns
never overwrite an earlier build.

### Build acceleration and reproducibility

| Component                                    | Strategy                                   | Reason                                                                                                      |
| -------------------------------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| GCC, glibc, binutils                         | Pinned Bootlin external toolchain          | Avoids roughly half an hour of toolchain compilation while retaining checksum verification                  |
| Linux kernel                                 | GameJay-built content-addressed prerelease | Avoids rebuilding an unchanged kernel without unsafe Buildroot stamp injection                              |
| Mesa, SDL2, GRUB, firmware, rootfs libraries | ABI-matched target/staging base prerelease | Avoids rebuilding the stable system base while preserving headers and pkg-config metadata                   |
| Libretro cores                               | GameJay-built content-addressed prerelease | Avoids repeated compilation and mutable upstream nightlies; corresponding source and licenses are published |
| RetroArch and menu                           | Build from pinned source against the base  | Preserves GameJay-specific KMS features while avoiding the expensive dependency rebuild                     |

Downloads and compiler objects use separate `.br-dl` and `.br-ccache` caches.
Both are saved even when a late step fails, so validated downloads and completed
compiler objects survive failed workflows. Cache identities include Buildroot
and the relevant package and configuration inputs.

The first build for a new dependency identity compiles and publishes the base,
kernel, and cores. Later builds reuse those immutable releases. Runtime assets
are separate from corresponding-source archives, so normal image builds do not
download source bundles. This is safer than caching partial Buildroot output
trees or consuming mutable nightly binaries.

Release compression uses multithreaded `xz -1`, and the outer ZIP stores the
already-compressed files instead of recompressing them. The initial `ROMDATA`
partition is 256 MiB rather than 2 GiB, which reduces image assembly, upload,
and download time while still leaving writable space for testing. The tradeoff
is that users should expand the final partition before adding a large library.

**UEFI** is preferred for modern hardware and uses GPT. **Legacy BIOS** is
provided for older PCs and uses MBR. Separate images keep each boot path
conventional and avoid fragile hybrid GRUB layouts.

## Build locally

A native Linux system, Linux VM, or WSL2 can build GameJay. A case-sensitive
Linux filesystem is recommended for the Buildroot and output directories.

Install the Ubuntu or Debian prerequisites:

```sh
sudo apt-get update
sudo apt-get install -y \
  bc bison build-essential cpio file flex git libelf-dev libncurses-dev \
  libssl-dev locales make patch perl python3 rsync unzip wget xz-utils
```

From the repository root:

```sh
wget https://buildroot.org/downloads/buildroot-2025.02.10.tar.xz
tar -xf buildroot-2025.02.10.tar.xz
make -C buildroot-2025.02.10 O="$PWD/output" \
  BR2_EXTERNAL="$PWD" gamejay_x86_64_defconfig
support/prepare-prebuilt.sh "$PWD/output"
make -C buildroot-2025.02.10 O="$PWD/output" -j"$(nproc)"
```

The helper downloads the checksum-verified base, kernel, and core releases
matching the tracked configuration. Reusing the same `output` directory
preserves Buildroot's incremental state. For persistent cross-output caching,
also pass `BR2_DL_DIR` and `BR2_CCACHE_DIR` as shown in the workflow.

The completed raw images are:

```text
output/images/gamejay.img
output/images/gamejay-bios.img
```

To restart from a clean build:

```sh
rm -rf output
```

## Write an SD card or USB stick

> [!WARNING]
> Raw writing erases the entire destination device. Verify the device name
> before running any command.

Decompress the image matching the target firmware:

```sh
xz -dk gamejay.img.xz
```

### Linux

```sh
sudo dd if=gamejay.img of=/dev/sdX bs=16M status=progress conv=fsync
sync
```

Use the whole device, such as `/dev/sdb`, not a partition such as `/dev/sdb1`.

### Windows

Decompress the artifact with 7-Zip, then write the `.img` with RawWrite, Rufus
in DD mode, balenaEtcher, or another raw disk writer.

### WSL2

Run an elevated PowerShell terminal:

```powershell
wsl --mount \\.\PHYSICALDRIVE3 --bare
wsl lsblk
wsl sudo dd if=/mnt/c/Users/you/Downloads/gamejay.img of=/dev/sdX bs=16M status=progress conv=fsync
wsl sync
wsl --unmount \\.\PHYSICALDRIVE3
```

Confirm the mapping with `Get-Disk` and `wsl lsblk`; Windows physical-drive and
Linux device numbers are not necessarily the same.

## Add ROMs, BIOS files, and saves

Reconnect the written device. Windows, Linux, and macOS can open its `ROMDATA`
exFAT partition. GameJay creates this layout on first boot:

```text
ROMDATA/
  arcade/
  bios/
  config/
  genesis/
  nes/
  ps1/
  saves/
  snes/
  states/
```

Place each game in the matching system directory. PlayStation BIOS files belong
in `bios`. Save files and states persist in `saves` and `states`.

The generated image reserves 768 MiB for the OS and 256 MiB for `ROMDATA`.
After writing to a larger card or drive, use Disk Management, GParted, or
another partition editor to grow the final `ROMDATA` partition into the
remaining unallocated space.

Only use ROMs and BIOS files that you are legally permitted to use.

## Controls

| Context        | Keyboard       | Controller     |
| -------------- | -------------- | -------------- |
| Move selection | Arrow keys     | D-pad          |
| Select         | Enter or Space | A              |
| Back           | Escape         | B              |
| Exit a game    | -              | Select + Start |

The image includes the PlayStation-style dual-stick mapping requested in the
design. RetroArch's udev auto-detection handles other standard USB gamepads.
Four or more controllers can be connected; the practical limit is the
available USB hardware.

## Boot and storage behavior

At startup, `S30romdata` locates the filesystem labeled `ROMDATA` rather than
assuming a fixed Linux device name. This supports SATA, USB, SD/MMC, and NVMe
boot media. If the partition is unavailable, GameJay mounts temporary RAM
storage so the launcher still starts and reports empty ROM lists.

The menu is launched by BusyBox `inittab` on `tty1`. Selecting a game forks
RetroArch and waits for it to exit; control then returns to the existing
launcher. Selecting **Power off** flushes pending writes before shutdown.

## Hardware support and tradeoffs

The kernel enables common x86 storage, USB HID, USB audio, Intel HDA audio,
Intel graphics, AMD Radeon/AMDGPU, Nouveau, EFI/VESA fallback, and virtual GPU
drivers. The userspace Mesa configuration includes Intel Crocus/Iris, older AMD
R300/R600, and software rendering.

Modern AMD RadeonSI acceleration requires Mesa LLVM and RadeonSI. It is not
enabled by default because LLVM significantly increases CI build time and image
size. Such systems can still boot, but may use a fallback renderer until those
defconfig options are added.

The image targets generic 64-bit x86 CPUs. It does not support 32-bit-only
processors or 32-bit UEFI firmware.

## Troubleshooting

**The device does not boot**

- Try `gamejay.img` for 64-bit UEFI and `gamejay-bios.img` for legacy BIOS.
- Disable Secure Boot; the generated GRUB and kernel are not signed.
- Enable USB or removable-device boot in firmware settings.
- Rewrite the image to the whole device and verify its checksum.

**The launcher does not appear**

- Try a different video output.
- Older or unusual GPUs may need additional kernel firmware or Mesa drivers.
- Remove `quiet loglevel=3` from `board/gamejay/grub.cfg`, rebuild, and inspect
  kernel output.

**No games are listed**

- Confirm the partition label is exactly `ROMDATA`.
- Check that ROMs are in the correct system directory.
- Reconnect the device to a PC and repair the exFAT filesystem if it was
  removed without a clean shutdown.

**No sound**

- ALSA uses the default device. Systems with both HDMI and analog outputs may
  require an explicit ALSA device in `rootfs-overlay/etc/retroarch.cfg`.

**A controller is not mapped correctly**

- Add a RetroArch udev profile under
  `rootfs-overlay/etc/retroarch-joypad-autoconfig/udev/` and rebuild.

## Customization

- Add or remove systems in `package/gamejay-menu/src/gamejay-menu.c`.
- Add a corresponding Buildroot core package under `package/`, update
  `configs/gamejay_cores_x86_64_defconfig`, and add its output to the core job.
- Change kernel hardware support in `board/gamejay/linux-fragment.config`.
- Tune RetroArch in `rootfs-overlay/etc/retroarch.cfg`.
- Change image partition sizes in `configs/gamejay_x86_64_defconfig` and
  `board/gamejay/post-image.sh`.
- Change boot arguments in `board/gamejay/grub.cfg`.

All source revisions are pinned in their package `.mk` files. Dependency tags
derive from those recipes and configurations, so relevant changes create new
immutable bundles rather than replacing old binaries.
