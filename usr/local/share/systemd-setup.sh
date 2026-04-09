#!/bin/bash
set -euo pipefail

DISABLED=(
    'systemd-homed.service'
)

ENABLED=(
    'systemd-resolved.service'
    'NetworkManager.service'
    'updatedb.timer'
    'lvm2-monitor.service'
    systemd-timesyncd.service
)

MASKED=(
    'systemd-networkd.service'
    'systemd-networkd.socket'
    'systemd-networkd-wait-online.service'
)


systemd-machine-id-setup --print
systemd-firstboot --prompt
systemctl preset-all



# Should not fail if missing service
set +e
echo "Explicit Disable"
for service in "${DISABLED[@]}"; do
    systemctl disable $service
done

echo "Explicit Enable"
for service in "${ENABLED[@]}"; do
    systemctl enable $service
done

echo "Explicit Mask"
for service in "${MASKED[@]}"; do
    systemctl mask $service
done
