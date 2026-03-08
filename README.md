## Abstract

A Gentoo setup with all the bells and whistles I could want.
Includes secure boot, and optionally zram backed build directory. This serves as documentation to be used alongside the handbook. The configuration is designed from my best knowledge and optimized for my ThinkPad e14 gen 6.

### System Info

CPU: AMD Ryzen 7 7735U with Radeon Graphics
Ram: 32GB

### Notes

- [ ] Find optimized kernel?
- [ ] Ugrd initramfs generator?
  - [ ] [[#`/etc/ugrd/config.toml` |Ugrd config]]
  - [ ] [[#`/etc/kernel/install.conf`|Kernel install config]]
- [ ] Niri + [Dotfiles](https://github.com/Stinky-C/dotfiles)

A way to download all configs and copy to correct places. Clones to a temp directory then makes and exracts an archive from the HEAD.
Tar will preserve permissions on the overwritten files and always start placing files in `/mnt/gentoo`

```sh
TMP_DIR=$(mktemp -D);  git clone --depth=1 https://github.com/Stinky-c/gentoo-config $TMP_DIR && git -C $TMP_DIR archive HEAD | tar xpv -C /mnt/gentoo
```

## Step by Step

1. Network setup
   1. Use Ethernet for ease of use
   2. [Handbook: Networking ](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Networking)
2. [Partition Layout](#partition-layout)
   1. [Creating the partition](#partition-creation-commands)
   2. Mount after completion
3. [Stage 3](#stage-3)
   1. Unpacking the stage 3 tar
   2. Chroot
4. Copy portage configurations
   1. [`make.conf`](etc/portage/make.conf)
   2. [`repos.conf/gentoo.conf`](etc/portage/repos.conf/gentoo.conf)
   3. [`repos.conf/guru.conf`](etc/portage/repos.conf/guru.conf)
   4. [`binrepos.conf/gentoo.conf`](etc/portage/binrepos.conf/gentoobinhost.conf)
   5. [`package.use/00cpu-flgs`](etc/portage/package.use/00cpu-flags)
   6. [`package.use/00video-drivers`](etc/portage/package.use/00video-drivers)
5. Update extras
   1. Update timezone: `ln -sf ../usr/share/zoneinfo/America/Los_Angeles /etc/localtime`
   2. Update locales: [`locale.gen`](etc/locale.gen) and `locale-gen`
6. Update repos
   1. Update keys: `getuto`
   2. `emerge --sync --quiet` first. If this does not work try the next one
   3. `emerge-webrsync` if behind a firewall
7. Update world
   1. `emerge --ask --verbose --update --deep --newuse --getbinpkg @world`
8. [Boot setup](#boot-setup)

## Partition Layout

| Label | FS Type    | Part. Type | Size         | Mount Point | Notes                                                                                                              |
| ----- | ---------- | ---------- | ------------ | ----------- | ------------------------------------------------------------------------------------------------------------------ |
| EFI   | fat32      | EFI        | 1G           | /efi        | Used for only EFI binaries. Leave 0.5G space to increase if needed.                                                |
| BOOT  | ext4       |            | 1G           | /boot       | A boot partition needed for GRUB configuration stuff.                                                              |
| SWAP  | swap       | swap       |              |             | [Swap Size - Gentoo Wiki](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#What_about_swap_space.3F) |
| ROOT  | LVM + ext4 |            | Rest of disk | /           | A plain ext4 partition.                                                                                            |

### Partition Creation Commands

```sh
mkfs.fat -F 32 -n EFI /dev/sdZ1
mkfs.ext4 -L BOOT /dev/sdZ2
mkswap -L SWAP /dev/sdZ3
# complete LVM setup
```

### Disk Device Name Example

Swap must be mounted with a command, note that swap uses a command. Make sure to create the correct folder on rootfs.

| Device file    | Purpose                                | Mount Point          |
| -------------- | -------------------------------------- | -------------------- |
| /dev/sdZ1      | Grub efi files                         | `[/mnt/gentoo]/efi`  |
| /dev/sdZ2      | Grub boot Configuration                | `[/mnt/gentoo]/boot` |
| /dev/sdZ3      | Swap space                             | `swapon /dev/sdZ3`   |
| /dev/sdZ4      | LVM Data                               |                      |
| /dev/vg0/lvol1 | LVM logical volume 0 on volume group 0 | `[/mnt/gentoo]/`     |

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

## Stage 3

[Stage 3 Mirrors](https://www.gentoo.org/downloads/mirrors/)
[Verifying and Validating](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Verifying_and_validating)

```sh
## Ensure working directroy is the mount partitions
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

## Network setup

Install `net-misc/networkmanager` if not added automatically, and configure upon first successful reboot.

## Packages

todo: break up into different stages of configuration

## Service Packages

| Identifier                | Notes                              | System Service                                                  |
| ------------------------- | ---------------------------------- | --------------------------------------------------------------- |
| `sys-fs/lvm`              | Auto mounting extra LVM Partitions | `lvm2-monitor.service`                                          |
| `net-misc/networkmanager` | Network configuration              | `NetworkManager.service` & `NetworkManager-wait-online.service` |

## TODO

| Identifier                          | Notes                                                              | System Service   |
| ----------------------------------- | ------------------------------------------------------------------ | ---------------- |
| `dev-vsc/git`                       |                                                                    |                  |
| `sys-apps/mlocate`                  |                                                                    | `updatedb.timer` |
| `app-shells/bash-completion`        |                                                                    |                  |
| `app-editors/vim`                   | Vim better than Nano                                               |                  |
| `sys-apps/zram-generator`           | See [[#`/etc/systemd/zram-generator.conf`\|zram-generator]] config |                  |
| `dev-vcs/git`                       |                                                                    |                  |
| `sys-block/io-scheduler-udev-rules` | Not needed, but may be useful for kernel tuning                    |                  |
| `sys-apps/bat`                      |                                                                    |

### File System tools

Tools to manage file systems

| Identifier          | File system |
| ------------------- | ----------- |
| `sys-fs/e2fsprogs`  | ext4        |
| `sys-fs/dosfstools` | Fat32       |
| `sys-fs/lvm`        | LVM         |

### DE Packages

These do not need to be emerged to boot the system, but they are important for a full system.

| Identifier                    | Notes                                        | System Service |
| ----------------------------- | -------------------------------------------- | -------------- |
| `gui-wm/niri`                 | AMD64 needs to be unmasked for this package. |                |
| `gui-apps/xwayland-satellite` | Used for Niri X11 intgeration.               |                |
| `gui-apps/swaybg`             | Dead simple background for niri.             |                |
| `gui-apps/swayidle`           | Idle management daemon.                      |                |
| `gui-apps/swaylock`           | Wayland locking.                             |                |
| `x11-terms/ghostty`           | Terminal for niri.                           |                |
| `x11-terms/ghostty-terminfo`  | Term info for ghostty.                       |                |

### Stage 5 Packages

Do not install any marked that will auto install, and follow numbered ones according to [Boot Setup](#boot-setup)

| Identifier                     | Auto-installed | Notes                                                            |
| ------------------------------ | -------------- | ---------------------------------------------------------------- |
| `sys-kernel/installkernel`     | X              |                                                                  |
| `sys-kernel/ugrd`              | X              | Ram disk generator                                               |
| `sys-boot/grub`                | X              | Boot loader                                                      |
| `sys-boot/os-prober`           | 1              | Grub tool to locate other OS boot partitions                     |
| `sys-kernel/gentoo-kernel-bin` | 2              |                                                                  |
| `sys-boot/shim`                | 3              | Signed secureboot shim to load grub. Signed with Microsoft keys. |
| `sys-boot/efibootmgr`          | X              | Used to manage efi vars                                          |
| `sys-boot/mokutil`             | 3              | Uses to manage Machine Owner Key for shim                        |
| `sys-kernel/linux-firmware`    | 2              |                                                                  |

## Boot Setup

Reference [Stage 5 packages](#stage-5-package) for selections to install.

Systemd profiles default to `kernel-install`, and GRUB requires kernels to be installed to `/boot`. Use ugrd for the ram disk and shim for secure boot.
Ensure [`/etc/portage/package.use/installkernel`] is correctly configured.

After `sys-kernel/installkernel` is done, install a dist-kernel (likely `sys-kernel/gentoo-kernel-bin`) then `sys-kernel/linux-firmware`.

After installing the kernel and firmware, use `emerge --config sys-kernel/gentoo-kernel-bin` (or which ever kernel) to ensure firmware is added.

Finally, extra commmands to finish a grub installation and configuration. Emerge selection 3.

```sh
# install grub to /efi
grub-install --efi-directory=/efi
# Copy signed shim, mokmanager, and grub
cp /usr/share/shim/BOOTX64.EFI /efi/EFI/gentoo/shimx64.efi
cp /usr/share/shim/mmx64.efi /efi/EFI/gentoo/mmx64.efi
cp /usr/lib/grub/grub-x86_64.efi.signed /efi/EFI/gentoo/grubx64.efi
# set efi to use shim to boot grub
# update disk and part
efibootmgr --disk /dev/sda --part 1 --create -L "gentoo via shim" -l '\EFI\gentoo\shimx64.efi'
```

## Tricks

- [Portage on tmpfs](https://wiki.gentoo.org/wiki/Portage_TMPDIR_on_tmpfs) or zram
- [zram](https://wiki.gentoo.org/wiki/Zram)
- [zswap on boot](https://wiki.gentoo.org/wiki/Zswap#Using_the_kernel_commandline)

## Issues

- Expand to only allow signed modules, and secure boot

## Links

- [Gentoo Overlay list](https://overlays.gentoo.org/)
- [Linux surface overlay](https://github.com/gentoo-mirror/gentoo-linux-surface-overlay)
- [Chromium-OS guides](https://www.chromium.org/chromium-os/developer-library/guides/) & [ebuild faq](https://chromium.googlesource.com/chromiumos/docs/+/master/portage/ebuild_faq.md)
- [Project Guru](https://wiki.gentoo.org/wiki/Project:GURU/Information_for_End_Users)
- [Plymouth](https://wiki.gentoo.org/wiki/Plymouth) - A screen for during boot
- virtio-fs - [home](https://virtio-fs.gitlab.io/) & [gentoo wiki](https://wiki.gentoo.org/wiki/Virtiofs)
