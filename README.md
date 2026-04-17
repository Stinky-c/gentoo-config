# Gentoo Config

## Abstract

A Gentoo setup with all the bells and whistles I could want.
Includes secure boot, and optionally zram backed build directory. This serves as documentation to be used alongside the handbook. The configuration is designed from my best knowledge and optimized for my ThinkPad e14 gen 6.

### System Info

CPU: AMD Ryzen 7 7735U with Radeon Graphics
Ram: 32 gigabytes

### Downloading This Repo

A way to download all configs and copy to correct places. Clones to a temp directory then makes and extracts an archive from the HEAD.
Tar will preserve permissions on the overwritten files and always start placing files in `/mnt/gentoo`

```sh
TMP_DIR=$(mktemp -D);  git clone --depth=1 https://github.com/Stinky-c/gentoo-config $TMP_DIR && git -C $TMP_DIR archive HEAD | tar xpv -C /mnt/gentoo
```

## Step by Step

1. Network setup
   1. Use Ethernet for ease of use
   2. [Handbook: Networking](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Networking)
2. [Partition Layout](#partition-layout)
   1. [Creating the partition](#partition-creation-commands)
   2. Mount after completion
3. [Stage 3](#stage-3)
   1. Unpacking the stage 3 tar
   2. Generate the fstab: `genfstab -U /mnt/gentoo`
   3. Chroot
4. Copy portage configurations
   1. May need to sync a clock. `chronyd -q`
   2. [Quick Download](#downloading-this-repo) (Must execute outside of chroot)
5. Update extras
   1. Update timezone: `ln -sf ../usr/share/zoneinfo/America/Los_Angeles /etc/localtime`
   2. Update locales: [`locale.gen`](etc/locale.gen) and `locale-gen`
6. Update repos
   1. Update keys: `getuto`
   2. Update the gentoo repo to include git. `emerge-webrsync`
   3. Oneshot git for now: `emerge --ask --oneshot dev-vcs/git`
   4. Use `emerge --sync` to update all repos.
7. Update world (optional)
   1. Emerge [`@toolkit`](#toolkit-set). This is a set of tools for updating the rest of the system
   2. Execute [`/usr/local/share/package/cpu`](etc/portage/package.use/00cpu-flags) to update CPU.
   3. Update [`00video-drivers`](etc/portage/package.use/00video-drivers)
   4. Update the world set. `emerge --ask --verbose --update --deep --newuse @world`
   5. Finally emerge [`@fstools`](#fs-tools-set), and [`@networking`](#networking-set)
   6. Configure system services `emerge --config --ask <atom>`
   - `mail-mta/nullmailer`
8. [Boot setup](#boot-setup)
9. [Continuing Setup](#continuing-setup)
   1. Run Systemd preset
   2. Set up user and root password
10. [Reboot Pre-checks](#reboot-pre-check)
11. [Desktop Setup](#desktop)

## Partition Layout

This partition layout is important to configure properly in fdisk. When using the proper [partition GUIDs](https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs) Systemd can automount everything including root. See [Discoverable Partition Specification](https://uapi-group.org/specifications/specs/discoverable_partitions_specification/).

| Label | FS Type    | Part. Type (fdisk)  | Size         | Mount Point | Notes                                                                                                              |
| ----- | ---------- | ------------------- | ------------ | ----------- | ------------------------------------------------------------------------------------------------------------------ |
| EFI   | fat32      | ESP (1)             | 1G           | /efi        | Used for only EFI binaries. Leave 0.5G space to increase if needed.                                                |
| BOOT  | ext4       | Extended boot (142) | 1G           | /boot       | Where kernel, and initramfs is kept.                                                                               |
| SWAP  | swap       | Swap (19)           | See Notes    |             | [Swap Size - Gentoo Wiki](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#What_about_swap_space.3F) |
| ROOT  | LVM + ext4 | LVM (44)            | Rest of disk | /           | A plain ext4 partition.                                                                                            |

### Partition Creation Commands

```sh
mkfs.fat -F 32 -n EFI /dev/sdZ1
mkfs.fat -F 32 -n BOOT /dev/sdZ2
mkswap -L SWAP /dev/sdZ3
# complete LVM setup
```

### Disk Device Name Example

Swap must be mounted with a command, note that swap uses a command. Make sure to create the correct folder on rootfs.

| Device file      | Purpose                                | Mount Point          |
| ---------------- | -------------------------------------- | -------------------- |
| `/dev/sdZ1`      | EFI files                              | `[/mnt/gentoo]/efi`  |
| `/dev/sdZ2`      | boot Entries                           | `[/mnt/gentoo]/boot` |
| `/dev/sdZ3`      | Swap space                             | `swapon /dev/sdZ3`   |
| `/dev/sdZ4`      | LVM Data                               |                      |
| `/dev/vg0/lvol1` | LVM logical volume 0 on volume group 0 | `[/mnt/gentoo]/`     |

## LVM Setup

[Wiki](https://wiki.gentoo.org/wiki/LVM)
Likely want to create a snapshot - [Wiki](https://wiki.gentoo.org/wiki/LVM#LVM2_snapshots_and_thin_snapshots)

```sh
## Create a phyiscal and virtaul volume on a partition
pvecreate /dev/sdZ4
vgcreate vg0 /dev/sdZ4
## Uses all free space in volume group
lvcreate --extents 100%FREE --name lvol1 vg0
## Format new Partition with ext4
mkfs.ext4 -L ROOT /dev/vg0/lvol1
```

[^](#step-by-step)

## Stage 3

[Stage 3 Mirrors](https://www.gentoo.org/downloads/mirrors/)
[Verifying and Validating](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Verifying_and_validating)

```sh
## Ensure working directory is the mount partitions
## This keeps stage3 on the root disk just in case
cd /mnt/gentoo

## Open links to the mirros pages
links https://www.gentoo.org/downloads/mirrors/
## `Region` > `North America` > `US`
## Pick a mirror > `releases` > `amd64` > `autobuilds`
## Pick a stage 3, likely `current-stage3-amd64-desktop-systemd`
## only need the tar file. See wiki for verifcation.

## Extract the stage 3 tar ball
## This preserves attributes and permissions included in the tar ball
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
```

## Chroot

Can be re-used if rebooting the live environment. Just mount the partitions from [the partition layout](#partition-layout). The `arch-chroot` provides a convivence method for chrooting to mount points, see the [wiki](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Mounting_the_necessary_filesystems) for the manual version. If using `arch-chroot` on not a mount point, use a bind mount `mount --bind /your/chroot /your/chroot`

```sh
## Copy resolv.conf
## Kinda need dns in a chroot. deref ensure the file is not a ref to nothing.
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/resolv.conf

## chroot
arch-chroot /mnt/gentoo
```

[^](#step-by-step)

## Packages

See package sets in [/etc/portage/sets](etc/portage/sets)

### Service Packages

List maintained in [`systemd-setup.sh`](usr/local/share/systemd-setup.sh) and [`10-custom.preset`](etc/systemd/system-preset/10-custom.preset).
Use the `systemd-setup.sh` script to setup systemd.

### Unsorted

| Identifier                          | Notes                                                               |
| ----------------------------------- | ------------------------------------------------------------------- |
| `app-editors/vim`                   | Vim better than Nano                                                |
| `sys-apps/zram-generator`           | See [`zram-generator.conf`](etc/systemd/zram-generator.conf) config |
| `sys-block/io-scheduler-udev-rules` | Not needed, but may be useful for kernel tuning                     |

### Networking Set

| Identifier                | Notes                  |
| ------------------------- | ---------------------- |
| `net-misc/networkmanager` | Chosen network manager |
| `net-vpn/wireguard-tools` | Wireguard stuff        |
| `net-vpn/tailscale`       |                        |

### Toolkit Set

| Identifier                   | Notes                                                                            |
| ---------------------------- | -------------------------------------------------------------------------------- |
| `dev-vcs/git`                |                                                                                  |
| `app-portage/cpuid2cpuflags` | Configures CPU Use flags                                                         |
| `app-shells/bash-completion` |                                                                                  |
| `sys-apps/bat`               | A more useful pager                                                              |
| `sys-apps/bat-extras`        | Extras for bat, like batman for man pages                                        |
| `app-portage/gentoolkit`     | Helpful utilies for portage. See [wiki](https://wiki.gentoo.org/wiki/Gentoolkit) |
| `app-portage/elogv`          | ncurses elog viewer                                                              |
| `sys-apps/mlocate`           | locate database update daemon                                                    |
| `dev-util/ccache`            | C/C++ object caching                                                             |
| `dev-util/sccache`           | C/C++/Rust object caching                                                        |
| `sys-kernel/modprobed-db`    | Tracks kernel modules to add. Useful for self compiled kernels.                  |
| `app-misc/jq`                | Used in my genfstab tool                                                         |

### FS Tools Set

| Identifier          | File system |
| ------------------- | ----------- |
| `sys-fs/e2fsprogs`  | ext4        |
| `sys-fs/dosfstools` | Fat32       |
| `sys-fs/lvm2`       | LVM         |

### Boot Set

| Identifier                     | Notes                                       |
| ------------------------------ | ------------------------------------------- |
| `sys-kernel/gentoo-kernel-bin` | Kernel with Gentoo patches. Simplest option |
| `sys-kernel/linux-firmware`    | Firmware needed for boot                    |
| `sys-firmware/intel-microcode` | Intel microcode                             |

| Identifier                 | Notes                                                                                                           |
| -------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `sys-kernel/installkernel` | Manages building, and bundling kernel into initramfs                                                            |
| `sys-kernel/ugrd`          | Ram disk generator                                                                                              |
| `sys-boot/shim`            | Signed secureboot shim to load `grubx64.efi`. Signed with Microsoft keys.                                       |
| `sys-boot/efibootmgr`      | Used to manage efi vars                                                                                         |
| `sys-boot/mokutil`         | Allows loading MOK (Machine Owner Key)                                                                          |
| `app-crypt/sbctl`          | Handles signing keys. Also includes a signing hook just in case                                                 |
| `app-crypt/efitools`       | Tools for managing EFI vars                                                                                     |
| `app-crypt/sbsigntools`    | Tools used by Gentoo to sign file                                                                               |
| `sys-apps/fwupd`           | Firmware update stuff                                                                                           |
| `__microcode__`            | A marker package for [`00cpu-flags`](etc/portage/package.use/00cpu-flags) to replace with the correct microcode |

### Desktop Set

See my [dotfiles](https://github.com/Stinky-c/dotfiles/tree/laptop-gentoo-niri)

Able to pull in zig as a binpkg to prevent ghostty building it from source. `emerge --ask --oneshot dev-lang/zig-bin`

Skip installing [mise](https://mise.jdx.dev/) via portage. I like how fast mise moves and would prefer to use that way.

| Identifier                          | Notes                                      |
| ----------------------------------- | ------------------------------------------ |
| `gui-wm/niri`                       |                                            |
| `sys-apps/xdg-desktop-portal`       |                                            |
| `sys-apps/xdg-desktop-portal-gtk`   | Niri docs recommend gtk as primary         |
| `sys-apps/xdg-desktop-portal-gnome` | then gnome as secondary                    |
| `gnome-base/gnome-keyring`          | Secret manager                             |
| `mate-extra/mate-polkit`            | gnome polkit is unmaintained               |
| `x11-terms/ghostty`                 | Terminal that I prefer                     |
| `media-fonts/monaspace`             | My primary monospace font. Present in guru |
| `media-fonts/jetbrains-mono`        | My fallback monospace font                 |
| `app-misc/fastfetch`                | pointless but fun                          |
| `gui-apps/noctalia-shell`           | [docs](https://docs.noctalia.dev/)         |
| `app-shells/starship`               | Cool terminal prompt                       |

## Boot Setup

[^](#step-by-step)

Systemd profiles default to `kernel-install`. Use `ugrd` for the ram disk and `shim` for secure boot.

First oneshot `app-crypt/sbctl` before anything else to generate secure boot signing keys. Then Emerge a kernel (`sys-kernel/gentoo-kernel-bin`), firmware (`sys-kernel/linux-firmware`), and the [`@boot`](#boot-set) set at the same time.
If targeting an Intel CPU, also emerge the Intel microcode `sys-firmware/intel-microcode`.

Finally, extra commands to finish a Grub installation and configuration.

```sh
# Needed for signing keys
emerge --oneshot --ask --verbose app-crypt/sbctl
sbctl create-keys

# Create a DER cert for mokutil to use
openssl x509 -in /var/lib/sbctl/keys/db/db.pem -outform der -out /boot/sbcert.der

# Now emerge the @boot set
# add /etc/kernel/cmdline
emerge --ask @boot

# Install systemd-boot to /efi
bootctl install --variables=no
cp /efi/EFI/systemd/systemd-bootx64.efi /efi/EFI/systemd/grubx64.efi

# Importing requires setting a MOK password. DO NOT FORGET PASSWORD
mokutil --import /boot/sbcert.der

# Copy signed shim, mokmanager
bash /usr/local/share/copy-shim.sh

# set efi to use shim to boot grub
# update disk and part
efibootmgr --disk /dev/sda --part 1 --create -L "gentoo via shim" -l '\EFI\systemd\shimx64.efi'

# Use -B to delete record and -b to specify which record
efibootmgr -B -b <num>
```

If full secure boot management is desired use [`sbctl` Only Setup](#sbctl-only-setup) otherwise follow keep following the above instruction. Without extra configuration both setups do not protect anything and only provide boot integrity.

### `sbctl` Only Setup

Use `app-crypt/sbctl` to manage everything. See `sbctl` [docs](https://github.com/Foxboron/sbctl/blob/master/docs/workflow-example.md) for the example workflow.
To enter secureboot Setup Mode delete all keys either with an `Clear Secure Boot Keys` option or manually delete all keys. Then save and reset.
To verify entering setup mode, boot and use sbctl to verify in setup mode (`sbctl status`).
After enrolling keys (make sure to add Microsoft keys), reboot to verify setup mode is now disabled (do not forget to sign necessary files before rebooting).

This creates keys and enrolls them.

```sh
# Check the status, secure boot must be off first to continue.
sbctl status

# Create the keys. Default location is '/var/lib/sbctl/keys'.
sbctl create-keys

# Enroll the newly create keys. This includes Microsoft keys too
sbctl enroll-keys -m

# If signing any extra files, use the following to also save the location to later resigning.
sbctl -s /path/to/file
sbctl -s /efi/EFI/gentoo/grubx64.efi
```

## Continuing Setup

Use systemd setup commands for systemd configuration.
Use [`systemd-setup.sh`](usr/local/share/systemd-setup.sh) to setup systemd.

```sh
# Need a root password
passwd

# Use the systemd setup script
# Sets machine id, hostname, and enables preset services
bash /usr/local/share/systemd-setup.sh
```

## User Setup

```sh
# Follow the prompts
useradd -m -G wheel,video,usb,audio -s /bin/bash cole
passwd cole
```

[^](#step-by-step)

## Reboot pre-Check

- UEFI boot records pointing to correct disk and both EFI binaries at `\EFI\gentoo\grubx64.efi` and `\EFI\gentoo\shimx64.efi`.
  - Use `efibootmgr` to see all UEFI boot records.
- Boot files present under `/boot/<machine id>`
  - `{amd,intel}-microcode` - Microcode
  - `initrd` - Ugrd Initramfs
  - `linux` - Kernel image
  - `sbcert.der` - MOK cert in DER format
- EFI files present.
  - `grubx64.efi` - Shim always loads this even though I am using systemd-boot
  - `mmx64.efi` - MOK Manager
  - `shimx64.efi` - Shim
  - `systemd-bootx64.efi`
- `/etc/fstab` contains mounted filesystems
  - Use `genfstab` from live ISO to configure

## Tricks

- [Portage on tmpfs](https://wiki.gentoo.org/wiki/Portage_TMPDIR_on_tmpfs) or zram
- [zram](https://wiki.gentoo.org/wiki/Zram)
- [zswap on boot](https://wiki.gentoo.org/wiki/Zswap#Using_the_kernel_commandline)

## Links

- [Gentoo Overlay list](https://overlays.gentoo.org/)
- [Linux surface overlay](https://github.com/gentoo-mirror/gentoo-linux-surface-overlay)
- [Chromium-OS guides](https://www.chromium.org/chromium-os/developer-library/guides/) & [ebuild faq](https://chromium.googlesource.com/chromiumos/docs/+/master/portage/ebuild_faq.md)
- [Project Guru](https://wiki.gentoo.org/wiki/Project:GURU/Information_for_End_Users)
- [Plymouth](https://wiki.gentoo.org/wiki/Plymouth) - A screen for during boot
- virtio-fs - [home](https://virtio-fs.gitlab.io/) & [gentoo wiki](https://wiki.gentoo.org/wiki/Virtiofs)
- [portage patches](https://wiki.gentoo.org/wiki//etc/portage/patches)
- [fwupd](https://wiki.gentoo.org/wiki/Fwupd)

## Ccache

Defined in [`ccache.conf`](etc/portage/env/ccache.conf). Apply to a package using `package.env`, ex: [`package.env/firefox`](etc/portage/package.env/firefox)

[`sccache.conf`](etc/portage/env/sccache.conf) may also work.

## Desktop

Emerge [`@desktop`](#desktop-set) and use chezmoi to include dotfiles.

## Drivers

- [Use Expand](https://packages.gentoo.org/useflags/expand#video_cards)
- [`make.conf` Video Cards](https://wiki.gentoo.org/wiki//etc/portage/make.conf#VIDEO_CARDS)
  - Update after changing: `emerge --ask --changed-use --deep @world`
  - Nvidia - `nvidia`
  - Nvidia open source - `nouveau`
    - Nvidia except Maxwell, Pascal, and Volta
  - AMD - `amdgpu radeonsi`
  - QEMU/KVM/Virtual - `virgl`
  - Intel - `intel`
    - Gen 1-3 use `intel i915`

## Index

A brief description of misc files.

### Scripts

These script are for convivence and are snippets taken from the wiki. They are stored inside `/usr/local/share/`

- [`copy-shim.sh`](usr/local/share/copy-shim.sh)
  - Copies shim, and mokmanager to the EFI directory.
- [`sccache-setup.sh`](usr/local/share/sccache-setup.sh)
  - Creates and sets permissions for sccache to be used
- [`systemd-setup.sh`](usr/local/share/systemd-setup.sh)
  - Configures systemd services before boot. Applies presets and enables/disable/masks services after presets.
- [`mkfstab.sh`](usr/local/share/mkfstab.sh)
  - I forgot genfstab from arch existed
- [`genfstab`](usr/local/share/genfstab)
  - The genfstab script copied from [glacion/genfstab](https://github.com/glacion/genfstab/tree/master).
