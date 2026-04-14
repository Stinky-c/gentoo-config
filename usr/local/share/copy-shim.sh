#!/bin/bash
set -euxo pipefail

cp --dereference /usr/share/shim/BOOTX64.EFI /efi/EFI/systemd/shimx64.efi
cp --dereference /usr/share/shim/mmx64.efi /efi/EFI/systemd/mmx64.efi
