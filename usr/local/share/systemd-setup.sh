#!/bin/bash
set -euxo pipefail

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

locate_service() {
    find /{lib,etc}/systemd/{user,system}/ -name $1
    return $?
}


systemd-machine-id-setup --print
systemd-firstboot --prompt
systemctl preset-all



for service in "${DISABLED[@]}"
do
    systemctl disable $service
end

for service in "${ENABLED[@]}"
do
    systemctl enable $service
end

for service in "${MASKED[@]}"
do
    systemctl mask $service
end
