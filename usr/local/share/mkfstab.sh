#!/bin/bash
echo "This was meant to generate an fstab file to make things easy."
echo "It already existed. Check out https://github.com/glacion/genfstab"
exit 1
set -euo pipefail

# EFI Partition details
EFI_PART=$(blkid -t LABEL=EFI -l -o json)
EFI_UUID=$(cat $EFI_PART | jq -r '.uuid')
EFI_TYPE=$(cat $EFI_PART | jq -r '.type')

BOOT_PART=$(blkid -t LABEL=BOOT -l -o json)
BOOT_UUID=$(cat $BOOT_PART | jq -r '.uuid')
BOOT_TYPE=$(cat $BOOT_PART | jq -r '.type')

ROOT_PART=$(blkid -t LABEL=ROOT -l -o json)
ROOT_UUID=$(cat $ROOT_PART | jq -r '.uuid')
ROOT_TYPE=$(cat $ROOT_PART | jq -r '.type')


SWAP_PART=$(blkid -t LABEL=SWAP -l -o json)
SWAP_UUID=$(cat $SWAP_PART | jq -r '.uuid')
ROOT_TYPE=$(cat $SWAP_PART | jq -r '.type')


if [ -f /etc/fstab ]; then
    mv /etc/fstab /etc/fstab.bak
fi

cat <<EOF > /etc/fstab
# <fs>      <mountpoint>    <type>  <opts>  <dump>  <pass>
# EFI
UUID=$EFI_UUID     /efi    $EFI_TYPE     defaults    0 2
# BOOT
UUID=$BOOT_UUID    /boot   $BOOT_TYPE    defaults    0 0
# SWAP
UUID=$SWAP_UUID    none    $SWAP_TYPE    defaults    0 0
# ROOT
UUID=$ROOT_UUID    /       $ROOT_TYPE    defaults    0 0
EOF
