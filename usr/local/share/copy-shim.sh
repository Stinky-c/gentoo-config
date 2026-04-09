#!/bin/bash
set -euxo pipefail

cp --dereference /usr/share/shim/BOOTX64.EFI /efi/EFI/gentoo/shimx64.efi
cp --dereference /usr/share/shim/mmx64.efi /efi/EFI/gentoo/mmx64.efi
cp --dereference /usr/lib/grub/grub-x86_64.efi.signed /efi/EFI/gentoo/grubx64.efi
